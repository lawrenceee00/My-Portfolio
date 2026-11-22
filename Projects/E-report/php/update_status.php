<?php
session_start();
include 'conn.php';

// Get the report ID and new status
$reportID = isset($_POST['report_id']) ? $_POST['report_id'] : '';
$status = isset($_POST['status']) ? $_POST['status'] : '';

// Validate inputs
if (empty($reportID) || empty($status)) {
    echo json_encode(["status" => "error", "message" => "Missing required fields"]);
    exit;
}

// Validate status value
$valid_statuses = ['pending', 'in-progress', 'rejected', 'resolved'];
if (!in_array($status, $valid_statuses)) {
    echo json_encode(["status" => "error", "message" => "Invalid status: " . $status]);
    exit;
}

try {
    // Update the status in the database using reportID
    $sql = "UPDATE reports SET status = :status WHERE reportID = :reportID";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':reportID', $reportID);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        // Send email notification to the user
        require_once __DIR__ . '/mailer.php';
        $emailResult = sendStatusNotification($reportID, $status);
        
        // Include email result in the response
        if ($emailResult['status'] === 'success') {
            echo json_encode(["status" => "success", "message" => "Status updated successfully and email notification sent to user"]);
        } else {
            // Status updated but email failed - still report success but include warning
            echo json_encode(["status" => "success", "message" => "Status updated successfully. Email notification could not be sent: " . $emailResult['message']]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Report not found or status unchanged"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => "Error: " . $e->getMessage()]);
}
?>

