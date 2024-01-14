const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();

// Define the path to the command.txt file
const filePath = path.join(__dirname, "command.txt");

// Define a route to serve the raw command.txt file
app.get("/", (req, res) => {
  // Check if the file exists
  if (fs.existsSync(filePath)) {
    // Read the file and send its contents as a response
    const fileContents = fs.readFileSync(filePath, "utf8");
    res.send(fileContents);
  } else {
    // If the file does not exist, send a 404 response
    res.status(404).send("File not found");
  }
});
const PORT = 3000; // You can change this port if needed
// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on PORT: ${PORT}`);
});
