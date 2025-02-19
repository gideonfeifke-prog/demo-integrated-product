const nextJest = require("next/jest");

const createJestConfig = nextJest({
  // Provide the path to your Next.js app to load next.config.js and .env files in your test environment
  dir: "./",
});

// Add any custom config to be passed to Jest
const customJestConfig = {
  setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
  testEnvironment: "jsdom",
  collectCoverage: true,
  coverageDirectory: "./", 
  collectCoverageFrom: [
    "./js-src/src/**/*.{js,jsx,ts,tsx}", 
    "!./js-src/src/**/*.test.{js,jsx,ts,tsx}", 
    "!./js-src/src/**/index.{js,ts}",
  ],
};

// createJestConfig is exported this way to ensure that next/jest can load the Next.js config which is async
module.exports = createJestConfig(customJestConfig);
