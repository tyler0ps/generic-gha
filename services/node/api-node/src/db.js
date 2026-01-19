const fs = require("fs");

const { Pool } = require("pg");

databaseUrl =
  process.env.DATABASE_URL ||
  fs.readFileSync(process.env.DATABASE_URL_FILE, "utf8");

console.log("Database configuration loaded");
console.log("SSL enabled: true");

const pool = new Pool({
  connectionString: databaseUrl,
  ssl: {
    rejectUnauthorized: false // AWS RDS uses self-signed certificates
  }
});

console.log("Database connection pool created");

// the pool will emit an error on behalf of any idle clients
// it contains if a backend error or network partition happens
pool.on("error", (err, client) => {
  console.error("Unexpected error on idle client", err);
  process.exit(-1);
});

const getDateTimeAndRequests = async () => {
  console.log("Attempting to connect to database for getDateTimeAndRequests...");
  const client = await pool.connect();
  console.log("Database connection established");

  try {
    console.log("Executing query: SELECT datetime and request count");
    const result = await client.query(`
      SELECT
      NOW() AS current_time,
      COUNT(*) AS request_count
      FROM public.request
      WHERE api_name = 'node';
    `);
    const currentTime = result.rows[0].current_time;
    const requestCount = result.rows[0].request_count;

    console.log(`Query successful - Time: ${currentTime}, Count: ${requestCount}`);

    return {
      currentTime,
      requestCount,
    };
  } catch (err) {
    console.error("Error in getDateTimeAndRequests:");
    console.error("Error message:", err.message);
    console.error("Error code:", err.code);
    console.error("Full stack:", err.stack);
  } finally {
    client.release();
    console.log("Database connection released");
  }
};

const insertRequest = async () => {
  console.log("Attempting to connect to database for insertRequest...");
  const client = await pool.connect();
  console.log("Database connection established");

  try {
    console.log("Executing query: INSERT request");
    const res = await client.query(
      "INSERT INTO request (api_name) VALUES ('node');",
    );
    console.log("Insert successful - rowCount:", res.rowCount);
    return;
  } catch (err) {
    console.error("Error in insertRequest:");
    console.error("Error message:", err.message);
    console.error("Error code:", err.code);
    console.error("Full stack:", err.stack);
  } finally {
    client.release();
    console.log("Database connection released");
  }
};

module.exports = { getDateTimeAndRequests, insertRequest };
