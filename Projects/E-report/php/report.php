<?php
session_start();
include 'conn.php';

header('Content-Type: application/json');

try {
    $firstname = isset($_SESSION['firstname']) ? $_SESSION['firstname'] : '';
    $lastname = isset($_SESSION['lastname']) ? $_SESSION['lastname'] : '';
    $category = isset($_POST['category']) ? $_POST['category'] : '';
    $description = isset($_POST['description']) ? $_POST['description'] : '';
    $location = isset($_POST['location']) ? $_POST['location'] : '';
    $userID = isset($_SESSION['userID']) ? $_SESSION['userID'] : null;

    // Basic field validation
    if ($category === '' || $description === '' || $location === '') {
        echo json_encode(["status" => "error", "message" => "Category, description and location are required."]);
        exit;
    }

    // Handle file upload
    $photoPath = '';
    if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = dirname(__DIR__) . '/uploads/';
        
        // Create uploads directory if it doesn't exist
        if (!is_dir($uploadDir)) {
            if (!mkdir($uploadDir, 0777, true)) {
                error_log("Failed to create uploads directory");
            }
        }
        
        $fileName = time() . '_' . basename($_FILES['photo']['name']);
        $targetFilePath = $uploadDir . $fileName;
        
        // Move uploaded file to target directory
        if (move_uploaded_file($_FILES['photo']['tmp_name'], $targetFilePath)) {
            $photoPath = 'uploads/' . $fileName;
        }
    }

    $latitude = isset($_POST['latitude']) && trim($_POST['latitude']) !== '' ? trim($_POST['latitude']) : '11.0506';
    $longitude = isset($_POST['longitude']) && trim($_POST['longitude']) !== '' ? trim($_POST['longitude']) : '122.4764';

    $sql = "INSERT INTO reports(firstname, lastname, category, description, location, photo, userID, status, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(1, $firstname);
    $stmt->bindParam(2, $lastname);
    $stmt->bindParam(3, $category);
    $stmt->bindParam(4, $description);
    $stmt->bindParam(5, $location);
    $stmt->bindParam(6, $photoPath);
    $stmt->bindParam(7, $userID);
    $stmt->bindParam(8, $latitude);
    $stmt->bindParam(9, $longitude);
    $stmt->execute();
    
    echo json_encode(["status" => "success", "message" => "Report successful"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>

