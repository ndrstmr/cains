import * as functions from "firebase-functions";
import *ానికిadmin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Define interfaces for our data structures (simplified)
interface Topic {
  id: string;
  titleEn: string; // Assuming English title for challenge generation
  // Add other fields if necessary for selection logic
}

interface VocabularyItem {
  id: string;
  word: string; // The word itself
  topicId: string;
  // Add other fields if necessary
}

interface DailyChallenge {
  id: string; // Typically YYYY-MM-DD
  userId: string;
  title: string;
  description: string;
  targetWord: string;
  targetTopicId: string;
  targetTopicTitleEn?: string; // Optional: for easier display
  targetVocabularyItemId: string;
  status: "open" | "completed" | "failed"; // Basic status
  dateCreated: string; // YYYY-MM-DD
  // Potentially add pointsForCompletion, etc.
}

/**
 * Generates a new daily challenge for the authenticated user if one doesn't already exist for the current day.
 * Expects an Authorization: Bearer <ID_TOKEN> header.
 */
export const generateDailyChallenge = functions.https.onRequest(
  async (request, response) => {
    // Enable CORS for local testing and if calling from a web app.
    // For production, configure origins more strictly.
    response.set("Access-Control-Allow-Origin", "*");
    response.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.set(
      "Access-Control-Allow-Headers",
      "Content-Type, Authorization"
    );

    if (request.method === "OPTIONS") {
      response.status(204).send("");
      return;
    }

    // Authentication: Firebase populates request.auth if the ID token is valid.
    if (!request.auth || !request.auth.uid) {
      functions.logger.warn("Unauthorized call to generateDailyChallenge: No UID, request.auth:", request.auth);
      response.status(401).send({
        error: "Unauthorized. User must be authenticated.",
      });
      return;
    }
    const userId: string = request.auth.uid;
    functions.logger.info(`generateDailyChallenge called by user ${userId}`);

    const today = new Date();
    const todayDateString = `${today.getFullYear()}-${String(
      today.getMonth() + 1
    ).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

    const userDocRef = db.collection("users").doc(userId);
    const challengeDocRef = userDocRef
      .collection("daily_challenges")
      .doc(todayDateString); // Use date as challenge ID for idempotency

    try {
      const userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        functions.logger.error(`User document for ${userId} not found.`);
        response.status(404).send({ error: "User profile not found." });
        return;
      }
      const userData = userDoc.data();

      // Check if a challenge for today is already in the user's main document
      if (
        userData?.dailyChallengeCompletion &&
        userData.dailyChallengeCompletion[todayDateString]
      ) {
        // Challenge already generated and recorded, try to fetch it
        const existingChallengeId =
          userData.dailyChallengeCompletion[todayDateString];
        const existingChallengeDoc = await userDoc
          .collection("daily_challenges")
          .doc(existingChallengeId)
          .get();

        if (existingChallengeDoc.exists) {
          functions.logger.info(
            `Daily challenge for ${todayDateString} for user ${userId} already exists. Returning existing one.`
          );
          response.status(200).send({
            message: "Daily challenge already exists for today.",
            challenge: existingChallengeDoc.data(),
          });
          return;
        } else {
          // Exists in map but not in subcollection - inconsistency.
          // Proceed to create it, the map will be overwritten.
          functions.logger.warn(
            `Challenge ${existingChallengeId} in user map but not in subcollection for user ${userId}. Will attempt to regenerate.`
          );
        }
      }

      // Fetch topics
      const topicsSnapshot = await db.collection("topics").get();
      if (topicsSnapshot.empty) {
        functions.logger.error("No topics found in Firestore.");
        response.status(500).send({ error: "No topics available to generate challenge." });
        return;
      }
      const topics: Topic[] = topicsSnapshot.docs.map(
        (doc) => ({id: doc.id, ...doc.data()} as Topic)
      );
      const randomTopic = topics[Math.floor(Math.random() * topics.length)];

      // Fetch vocabulary for the selected topic
      const vocabularySnapshot = await db
        .collection("vocabulary")
        .where("topicId", "==", randomTopic.id)
        .get();

      if (vocabularySnapshot.empty) {
        functions.logger.error(`No vocabulary items found for topic ${randomTopic.id}.`);
        // Optionally, try another topic or report error
        response.status(500).send({
            error: `No vocabulary items for topic '${randomTopic.titleEn}'.`,
          });
        return;
      }
      const vocabularyItems: VocabularyItem[] = vocabularySnapshot.docs.map(
        (doc) => ({id: doc.id, ...doc.data()} as VocabularyItem)
      );
      const randomVocabItem = vocabularyItems[Math.floor(Math.random() * vocabularyItems.length)];

      // Generate challenge
      const newChallenge: DailyChallenge = {
        id: todayDateString, // Use date as ID
        userId: userId,
        title: `Daily Challenge: ${randomTopic.titleEn}`,
        description: `Today's task: Find the word "${randomVocabItem.word}" related to ${randomTopic.titleEn}.`,
        targetWord: randomVocabItem.word,
        targetTopicId: randomTopic.id,
        targetTopicTitleEn: randomTopic.titleEn,
        targetVocabularyItemId: randomVocabItem.id,
        status: "open",
        dateCreated: todayDateString,
      };

      // Save challenge to subcollection and update user's main document
      // Using a batch to ensure atomicity of these two writes.
      const batch = db.batch();
      batch.set(challengeDocRef, newChallenge); // Create/overwrite challenge in subcollection
      batch.set(
        userDocRef,
        {
          dailyChallengeCompletion: {
            [todayDateString]: newChallenge.id, // Map date to challenge ID
          },
        },
        {merge: true} // Merge to not overwrite other user fields
      );

      await batch.commit();

      functions.logger.info(`Daily challenge ${newChallenge.id} generated for user ${userId}.`);
      response.status(201).send({
        message: "Daily challenge generated successfully.",
        challenge: newChallenge,
      });
    } catch (error) {
      functions.logger.error(
        `Error in generateDailyChallenge for user ${userId}:`,
        error
      );
      // Type guard for FirebaseError
      let errorMessage = "Internal server error.";
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      response.status(500).send({error: errorMessage});
    }
  }
);
