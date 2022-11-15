const AWS = require('aws-sdk')

// === CONFIG ===
// 🚨 Don't forget to configure CORS in AWS' API Gateway configuration
const BUCKET = process.env.bucket;
const REGION = process.env.region;
const SECRET = process.env.secret || undefined; // (Optional) set a secret. Needs to be added to the Sanity plugin as well!

const s3 = new AWS.S3({
  region: REGION,
});

const SHARED_HEADERS = {
  "Content-Type": "application/json",
};

exports.handler = async (event, _context, callback) => {
  const method =
    event.httpMethod ||
    event?.requestContext?.httpMethod ||
    event?.requestContext?.http?.method;
  if (method?.toUpperCase() === "OPTIONS") {
    return callback(null, {
      statusCode: 200,
      body: JSON.stringify(event),
      headers: SHARED_HEADERS,
    });
  }

  let body = {};
  try {
    body = JSON.parse(event.body || "{}");
  } catch (error) {
    return callback(null, {
      statusCode: 400,
      body: JSON.stringify({
        message: "Missing body",
        ...event,
      }),
      headers: SHARED_HEADERS,
    });
  }

  // Event is an object with the JSON data sent to the function
  const { fileKey, secret } = body || {};

  if (typeof SECRET !== "undefined" && secret !== SECRET) {
    return callback(null, {
      statusCode: 401,
      body: JSON.stringify({
        message: "Unauthorized",
        ...event,
      }),
      headers: SHARED_HEADERS,
    });
  }

  if (!fileKey || typeof fileKey !== "string") {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: "Missing file key",
      }),
      headers: SHARED_HEADERS,
    };
  }

  try {
    await s3
      .deleteObject({
        Bucket: BUCKET,
        Key: fileKey,
      })
      .promise();
    return callback(null, {
      statusCode: 200,
      body: JSON.stringify({
        message: "success!"
      }),
      headers: SHARED_HEADERS,
    });
  } catch (error) {
    return callback(error, {
      statusCode: 500,
      body: JSON.stringify(error),
      headers: SHARED_HEADERS,
    });
  }
};