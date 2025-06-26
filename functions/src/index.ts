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

// region OCR Function
// -----------------------------------------------------------------------------

// Imports for Google Cloud Vision API
import * as vision from "@google-cloud/vision";

interface OcrRequestData {
  imageData: string; // Base64 encoded image string
  mimeType?: string; // Optional: e.g., "image/png", "image/jpeg"
}

interface WordData {
  text: string;
  bounds: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

interface OcrResponseData {
  words: WordData[];
}

/**
 * Processes an image using Google Cloud Vision API to extract text and bounding boxes.
 * This is an HttpsCallable function.
 *
 * @param data The request data.
 * @param data.imageData Base64 encoded string of the image.
 * @param data.mimeType Optional. The MIME type of the image.
 * @param context The context of the function call, including authentication details.
 * @returns A Promise that resolves with an OcrResponseData object.
 * @throws An HttpsError if authentication fails, input is invalid, or an API error occurs.
 */
export const processImageForOcr = functions.https.onCall(
  async (data: OcrRequestData, context): Promise<OcrResponseData> => {
    // 1. Authentication
    if (!context.auth) {
      functions.logger.warn("processImageForOcr: Unauthenticated call.");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }
    const userId = context.auth.uid;
    functions.logger.info(
      `processImageForOcr called by user ${userId}. Image data length (chars): ${data.imageData?.length}`
    );

    // 2. Input Validation
    if (!data.imageData || typeof data.imageData !== "string") {
      functions.logger.warn("processImageForOcr: Missing or invalid imageData.", {
        userId,
      });
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid 'imageData' string."
      );
    }

    // 3. Initialize Vision Client
    // It's generally recommended to initialize clients outside the function scope
    // if they can be reused across invocations for better performance.
    // However, for simplicity and to ensure fresh credentials, initializing here is also common.
    // For production, consider initializing `vision.ImageAnnotatorClient()` globally.
    const client = new vision.ImageAnnotatorClient();

    try {
      // 4. Prepare Image Request
      // Remove potential Base64 prefix (e.g., "data:image/jpeg;base64,")
      const base64Image = data.imageData.startsWith("data:") ?
        data.imageData.substring(data.imageData.indexOf(",") + 1) :
        data.imageData;

      const imageRequest = {
        image: {
          content: base64Image,
        },
        features: [{type: "TEXT_DETECTION"}],
        // Optionally, add imageContext for language hints if known
        // imageContext: {
        //   languageHints: ["de", "en"], // Prioritize German and English
        // },
      };

      // 5. Call Vision API
      functions.logger.info(
        `Calling Vision API for text detection for user ${userId}.`
      );
      const [visionResult] = await client.textDetection(imageRequest);
      functions.logger.info(
        `Vision API response received for user ${userId}.`
      );


      // 6. Process Results
      if (visionResult.error) {
        functions.logger.error(
          `Vision API returned an error for user ${userId}:`,
          visionResult.error
        );
        throw new functions.https.HttpsError(
          "internal",
          `Vision API Error: ${visionResult.error.message}`
        );
      }

      const words: WordData[] = [];
      const textAnnotations = visionResult.textAnnotations;

      if (textAnnotations && textAnnotations.length > 0) {
        // The first annotation (index 0) is typically the full detected text block.
        // Subsequent annotations are individual words or symbols.
        // We iterate from the second element to get individual words.
        for (let i = 1; i < textAnnotations.length; i++) {
          const annotation = textAnnotations[i];
          if (annotation.description && annotation.boundingPoly?.vertices) {
            const vertices = annotation.boundingPoly.vertices;
            // Calculate bounds: min/max x and y
            const xCoordinates = vertices.map((v) => v.x || 0);
            const yCoordinates = vertices.map((v) => v.y || 0);

            const minX = Math.min(...xCoordinates);
            const minY = Math.min(...yCoordinates);
            const maxX = Math.max(...xCoordinates);
            const maxY = Math.max(...yCoordinates);

            words.push({
              text: annotation.description,
              bounds: {
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY,
              },
            });
          }
        }
        functions.logger.info(
          `Extracted ${words.length} words for user ${userId}.`
        );
      } else {
        functions.logger.info(
          `No text annotations found in Vision API response for user ${userId}.`
        );
      }

      // 7. Format Output
      return {words};
    } catch (error) {
      functions.logger.error(
        `Error in processImageForOcr for user ${userId}:`,
        error
      );
      if (error instanceof functions.https.HttpsError) {
        throw error; // Re-throw HttpsError directly
      }
      // For other errors, wrap them in a generic HttpsError
      let errorMessage = "Internal server error during image processing.";
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      throw new functions.https.HttpsError("internal", errorMessage);
    }
  }
);

// endregion
// -----------------------------------------------------------------------------

// Interface for the expected request body for generateAiDefinition
interface GenerateAiDefinitionRequest {
  word: string;
}

// Interface for the AI-generated vocabulary item structure (matches VocabularyItem in Flutter app)
// This is a more detailed version for the AI function's output.
interface AiVocabularyOutput {
  id: string; // Will be generated (e.g., "ai-" + word + timestamp)
  word: string; // The input word
  definitions: { [key: string]: string }; // e.g., { "de": "...", "en": "...", "es": "..." }
  synonyms: string[]; // e.g., ["synonym1", "synonym2"]
  collocations: string[]; // e.g., ["collocation1", "collocation2"]
  exampleSentences: { [key: string]: string[] }; // e.g., { "de": ["satz1", "satz2"], "en": ["sentence1"] }
  level: string; // Default C1
  sourceType: string; // Will be "ai_added"
  topicId: string; // Default "ai_researched"
  grammarHint?: string; // e.g., "Noun, feminine"
  contextualText?: string; // e.g., "Used in formal contexts..."
}


/**
 * Generates AI-based information for a given word.
 * Expects an Authorization: Bearer <ID_TOKEN> header and a JSON body { "word": "example" }.
 */
export const generateAiDefinition = functions.https.onRequest(
  async (request, response) => {
    // Enable CORS
    response.set("Access-Control-Allow-Origin", "*");
    response.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (request.method === "OPTIONS") {
      response.status(204).send("");
      return;
    }

    // Authentication
    if (!request.auth || !request.auth.uid) {
      functions.logger.warn("Unauthorized call to generateAiDefinition: No UID", {auth: request.auth});
      response.status(401).send({error: {message: "Unauthorized. User must be authenticated."}});
      return;
    }
    const userId = request.auth.uid;
    functions.logger.info(`generateAiDefinition called by user ${userId}`);

    // Validate request body
    if (request.method !== "POST") {
      response.status(405).send({error: {message: "Method Not Allowed. Please use POST."}});
      return;
    }

    const requestBody = request.body as GenerateAiDefinitionRequest;
    const wordToDefine = requestBody.word;

    if (!wordToDefine || typeof wordToDefine !== "string" || wordToDefine.trim() === "") {
      functions.logger.warn("generateAiDefinition: Missing or invalid 'word' in request.", {body: request.body});
      response.status(400).send({error: {message: "Bad Request. Please provide a 'word' in the JSON body."}});
      return;
    }

    functions.logger.info(`User ${userId} requested definition for word: "${wordToDefine}"`);

    // TODO: Implement Google Gemini Pro API call
    // 1. Get API Key from environment variables (e.g., functions.config().gemini.apikey)
    //    Ensure it's set: firebase functions:config:set gemini.apikey="YOUR_API_KEY"
    // const apiKey = functions.config().gemini?.apikey;
    // if (!apiKey) {
    //   functions.logger.error("Gemini API key not configured.");
    //   response.status(500).send({ error: { message: "Internal server error: AI service not configured." } });
    //   return;
    // }
    // 2. Construct the prompt for Gemini API.
    //    Prompt should request all necessary fields:
    //    - Definitions in German, English, Spanish (C1 level)
    //    - Min. 2 example sentences per language
    //    - Min. 3 synonyms
    //    - Min. 3 collocations
    //    - Grammar hint (e.g., "Nomen, feminin")
    //    - Contextual short text (when the word is used)
    //    - Request output in a structured JSON format if possible, or parseable text.

    // 3. Make the API call to Gemini. (Using a placeholder for now)
    //    Example using a hypothetical SDK or fetch:
    //    const geminiResponse = await callGeminiApi(apiKey, prompt, wordToDefine);

    // 4. Parse the Gemini response and map it to AiVocabularyOutput structure.

    // Placeholder for AI response:
    try {
      // Simulate AI processing time
      await new Promise((resolve) => setTimeout(resolve, 1500));

      const generatedId = `ai-${wordToDefine.toLowerCase().replace(/\s+/g, "-")}-${Date.now()}`;

      const mockAiData: AiVocabularyOutput = {
        id: generatedId,
        word: wordToDefine,
        definitions: {
          de: `Mock Definition für ${wordToDefine} auf Deutsch (C1 Niveau).`,
          en: `Mock definition for ${wordToDefine} in English (C1 level).`,
          es: `Definición simulada para ${wordToDefine} en español (nivel C1).`,
        },
        synonyms: ["MockSynonym1", "MockSynonym2", "MockSynonym3"],
        collocations: [`häufig mit ${wordToDefine}`, `${wordToDefine} verwenden`, `typisch für ${wordToDefine}`],
        exampleSentences: {
          de: [
            `Dies ist ein Beispielsatz für ${wordToDefine}.`,
            `Ein weiterer deutscher Satz, der ${wordToDefine} enthält.`,
          ],
          en: [
            `This is an example sentence for ${wordToDefine}.`,
            `Another English sentence containing ${wordToDefine}.`,
          ],
          es: [
            `Esta es una frase de ejemplo para ${wordToDefine}.`,
            `Otra frase en español que contiene ${wordToDefine}.`,
          ],
        },
        level: "C1",
        sourceType: "ai_added", // This should match SourceType enum string representation
        topicId: "ai_researched", // A generic topic ID for AI-added words
        grammarHint: "MockGrammar (z.B. Nomen, feminin)",
        contextualText: `Dieses Wort '${wordToDefine}' wird typischerweise in mock Kontexten verwendet, um seine mock Natur zu unterstreichen.`,
      };

      functions.logger.info(`Successfully generated mock AI definition for "${wordToDefine}" for user ${userId}`);
      response.status(200).send(mockAiData);
    } catch (error) {
      functions.logger.error(`Error during AI generation placeholder for word "${wordToDefine}" for user ${userId}:`, error);
      // Type guard for error
      let errorMessage = "Failed to generate AI definition due to an internal error.";
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      response.status(500).send({error: {message: errorMessage}});
    }
  }
);
