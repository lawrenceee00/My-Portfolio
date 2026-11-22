<?php
session_start();
include 'conn.php';
include 'mailer.php';

$email = $_POST['email'];
$scholarship = $_POST['scholarship'];
$paymentMethod = $_POST['paymentMethod'];

// Get student info from session
$studentID = $_SESSION['studentID'] ?? null;
$firstname = $_SESSION['firstname'] ?? '';
$lastname = $_SESSION['lastname'] ?? '';
$studentName = trim($firstname . ' ' . $lastname);

$sql = "INSERT INTO payment (email, scholarship, paymentmethod) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bindParam(1, $email);
$stmt->bindParam(2, $scholarship);
$stmt->bindParam(3, $paymentMethod);

if($stmt->execute()) {
    // Get all enrolled subjects for the student
    $subjectSql = "SELECT subjectname, subjectcode FROM subject WHERE studentID = ?";
    $subjectStmt = $conn->prepare($subjectSql);
    $subjectStmt->bindParam(1, $studentID);
    $subjectStmt->execute();
    $subjectRows = $subjectStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Build subjects list for email
    $subjectsList = [];
    if (!empty($subjectRows)) {
        foreach ($subjectRows as $row) {
            $subjectsList[] = $row['subjectname'] . ' (' . $row['subjectcode'] . ')';
        }
        $subjectNames = implode(', ', $subjectsList);
        $subjectName = $subjectsList[0]; // First subject for backward compatibility
        $subjectCode = $subjectRows[0]['subjectcode'];
    } else {
        $subjectNames = 'No subjects enrolled';
        $subjectName = 'Your enrolled subject';
        $subjectCode = 'N/A';
    }
    
    // Send email notification with all subjects
    $emailResult = sendPaymentNotification($email, $studentName, $subjectNames);
    
    if ($emailResult['status'] === 'success') {
        echo json_encode([
            "status" => "success", 
            "message" => "Payment recorded successfully. Email notification sent!"
        ]);
    } else {
        // Payment recorded but email failed - still success for payment
        echo json_encode([
            "status" => "success", 
            "message" => "Payment recorded successfully. Note: " . $emailResult['message']
        ]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Failed to record payment"]);
}
?>
