const { getDateTimeAndRequests, insertRequest } = require("./db");

const express = require("express");
const morgan = require("morgan");

const app = express();
const port = process.env.PORT || 3000;

// setup the logger
app.use(morgan("tiny"));

// Routes with /api/node prefix
app.get("/api/node", async (req, res) => {
  await insertRequest();
  const response = await getDateTimeAndRequests();
  response.api = "node";
  res.send(response);
});

app.get("/api/node/ping", async (_, res) => {
  res.send("pong");
});

app.get("/api/node/health", async (_, res) => {
  res.send("ok");
});

const server = app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});

process.on("SIGTERM", () => {
  console.debug("SIGTERM signal received: closing HTTP server");
  server.close(() => {
    console.debug("HTTP server closed");
  });
});
