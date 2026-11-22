<?php
session_start();

include 'conn.php';

$email = $_POST['email'];
$password = $_POST['password'];

$sql = "SELECT * FROM users WHERE email = ?";
$stmt = $conn->prepare($sql);
$stmt->bindParam(1, $email);
$stmt->execute();

$user = $stmt->fetch(PDO::FETCH_ASSOC);

if ($user && password_verify($password, $user['password'])) {
    // Login successful - set session
    $_SESSION['userID'] = $user['userID'];
    $_SESSION['email'] = $user['email'];
    $_SESSION['firstname'] = $user['firstname'];
    $_SESSION['lastname'] = $user['lastname'];
    
    // Check if user is admin (case-insensitive comparison)
    $redirectUrl = "ereport.php";
    if (strtolower($email) === "admin@gmail.com") {
        $redirectUrl = "admin.php";
    }
    
    echo json_encode([
        "status" => "success",
        "message" => "Login successful",
        "redirect" => $redirectUrl,
        "debug" => [
            "email" => $email,
            "is_admin" => (strtolower($email) === "admin@gmail.com")
        ]
    ]);
} else {
    // Login failed
    echo json_encode([
        "status" => "error",
        "message" => "Invalid email or password"
    ]);
}
?>

