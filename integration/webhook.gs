/**
 * YouthChain — Google Apps Script Webhook
 * Youth For Change TT | youthforchangett.com
 *
 * Receives quiz results from the WordPress platform,
 * stores them in Google Sheets, and prevents duplicate submissions.
 *
 * Sheet Structure (Raw Data):
 * A: Timestamp
 * B: User ID (WordPress/BuddyBoss user ID)
 * C: Name
 * D: Email
 * E: School
 * F: Score
 * G: Tokens Earned
 * H: Anonymous ID (off-chain reference to blockchain record)
 *
 * Privacy Model:
 * - Personal data (name, email, school) stored here ONLY — never on-chain
 * - Anonymous ID links this record to the blockchain without exposing identity
 * - User ID used for duplicate prevention only
 *
 * Deploy as: Web App
 * Execute as: Me
 * Access: Anyone
 */

// ─── DUPLICATE CHECK (GET) ────────────────────────────────────────────────────

function doGet(e) {
  // Check if a user has already submitted
  if (e.parameter.action === "check" && e.parameter.userId) {
    var sheet = SpreadsheetApp.getActiveSpreadsheet()
      .getSheetByName("Raw Data");
    var data  = sheet.getDataRange().getValues();
    var found = false;

    for (var i = 1; i < data.length; i++) {
      if (String(data[i][1]) === String(e.parameter.userId)) {
        found = true;
        break;
      }
    }

    return ContentService
      .createTextOutput(JSON.stringify({
        alreadySubmitted: found
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }

  return ContentService
    .createTextOutput(JSON.stringify({ status: "ok" }))
    .setMimeType(ContentService.MimeType.JSON);
}

// ─── QUIZ SUBMISSION (POST) ───────────────────────────────────────────────────

function doPost(e) {
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet()
      .getSheetByName("Raw Data");

    var data = JSON.parse(e.postData.contents);

    // Block duplicate submissions by WordPress User ID
    var existing = sheet.getDataRange().getValues();
    for (var i = 1; i < existing.length; i++) {
      if (String(existing[i][1]) === String(data.userId)) {
        return ContentService
          .createTextOutput(JSON.stringify({
            status:  "duplicate",
            message: "This user has already submitted"
          }))
          .setMimeType(ContentService.MimeType.JSON);
      }
    }

    // Generate anonymous ID — this is what gets referenced on-chain
    // Format: YFC-XXXXXXXXX (no personal data)
    var anonymousId = "YFC-" + Math.random()
      .toString(36)
      .substr(2, 9)
      .toUpperCase();

    // Append row to Raw Data sheet
    sheet.appendRow([
      new Date(),          // A: Timestamp
      data.userId,         // B: WordPress User ID (for duplicate check only)
      data.name,           // C: Full name (off-chain only)
      data.email,          // D: Email (off-chain only)
      data.school,         // E: School (off-chain only)
      data.score,          // F: Score
      data.tokensEarned,   // G: CHG tokens earned
      anonymousId          // H: Anonymous ID (referenced on-chain)
    ]);

    // Update M&E Summary sheet
    updateMESummary();

    return ContentService
      .createTextOutput(JSON.stringify({
        status:       "success",
        anonymousId:  anonymousId,
        tokensEarned: data.tokensEarned
      }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch(error) {
    return ContentService
      .createTextOutput(JSON.stringify({
        status:  "error",
        message: error.toString()
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// ─── M&E SUMMARY AUTO-UPDATE ─────────────────────────────────────────────────

function updateMESummary() {
  var rawSheet     = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Raw Data");
  var summarySheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("M&E Summary");

  var data         = rawSheet.getDataRange().getValues();
  var dataRows     = data.slice(1); // Remove header row

  if (dataRows.length === 0) return;

  // Calculate M&E metrics
  var totalSubmissions  = dataRows.length;
  var totalTokensIssued = dataRows.reduce(function(sum, row) {
    return sum + (parseFloat(row[6]) || 0);
  }, 0);

  var totalScore = dataRows.reduce(function(sum, row) {
    return sum + (parseInt(row[5]) || 0);
  }, 0);

  var averageScore = totalSubmissions > 0
    ? (totalScore / totalSubmissions).toFixed(2)
    : 0;

  var perfectScores = dataRows.filter(function(row) {
    return parseInt(row[5]) === 5;
  }).length;

  var perfectScorePct = totalSubmissions > 0
    ? ((perfectScores / totalSubmissions) * 100).toFixed(1) + "%"
    : "0%";

  // School breakdown
  var schools = {};
  dataRows.forEach(function(row) {
    var school = row[4] || "Not specified";
    schools[school] = (schools[school] || 0) + 1;
  });

  // Write M&E Summary
  summarySheet.clearContents();

  summarySheet.getRange("A1").setValue("YouthChain M&E Dashboard");
  summarySheet.getRange("A1").setFontSize(16).setFontWeight("bold");
  summarySheet.getRange("A2").setValue("Last Updated: " + new Date().toLocaleString());

  summarySheet.getRange("A4").setValue("METRIC");
  summarySheet.getRange("B4").setValue("VALUE");
  summarySheet.getRange("A4:B4").setFontWeight("bold").setBackground("#2D1B69").setFontColor("#FFFFFF");

  var metrics = [
    ["Total Youth Submissions",    totalSubmissions],
    ["Average Score (out of 5)",   averageScore],
    ["Perfect Scores",             perfectScores],
    ["Perfect Score Rate",         perfectScorePct],
    ["Total CHG Tokens Issued",    totalTokensIssued.toFixed(1)],
    ["SDG Indicator (SDG 4.4)",    totalSubmissions + " youth completed digital skills assessment"],
  ];

  metrics.forEach(function(metric, index) {
    summarySheet.getRange("A" + (5 + index)).setValue(metric[0]);
    summarySheet.getRange("B" + (5 + index)).setValue(metric[1]);
  });

  // School breakdown
  summarySheet.getRange("A12").setValue("SCHOOL BREAKDOWN");
  summarySheet.getRange("A12").setFontWeight("bold");
  summarySheet.getRange("B12").setValue("SUBMISSIONS");
  summarySheet.getRange("A12:B12").setBackground("#FF6B1A").setFontColor("#FFFFFF");

  var row = 13;
  Object.keys(schools).forEach(function(school) {
    summarySheet.getRange("A" + row).setValue(school);
    summarySheet.getRange("B" + row).setValue(schools[school]);
    row++;
  });
}
