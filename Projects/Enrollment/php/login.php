<?php
session_start();
include 'conn.php';

header('Content-Type: application/json');

$email = trim($_POST['email'] ?? '');
$password = trim($_POST['password'] ?? '');

if ($email === '' || $password === '') {
    echo json_encode(["status" => "error", "message" => "Email and password are required"]);
    exit;
}

$sql = "SELECT studentID, firstname, lastname, email, password FROM studentinfo WHERE email = ? LIMIT 1";
$stmt = $conn->prepare($sql);
$stmt->execute([$email]);

$student = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$student) {
    echo json_encode(["status" => "error", "message" => "User not found"]);
    exit;
}

$dbPassword = $student['password'] ?? '';
$loginOk = false;

/**
 * Case A: DB password is hashed (starts with $2y$ / $2a$ / $argon2...)
 */
if ($dbPassword !== '' && (str_starts_with($dbPassword, '$2y$') || str_starts_with($dbPassword, '$2a$') || str_starts_with($dbPassword, '$argon2'))) {
    if (password_verify($password, $dbPassword)) {
        $loginOk = true;
    }
} else {
    /**
     * Case B: DB password is plaintext (old data)
     * If user typed the exact same password, allow login and UPGRADE to hash.
     */
    if (hash_equals($dbPassword, $password)) {
        $loginOk = true;

        // Upgrade plaintext password to hashed password
        $newHash = password_hash($password, PASSWORD_DEFAULT);
        $up = $conn->prepare("UPDATE studentinfo SET password = ? WHERE studentID = ?");
        $up->execute([$newHash, $student['studentID']]);
    }
}

if (!$loginOk) {
    echo json_encode(["status" => "error", "message" => "Invalid password"]);
    exit;
}

// ✅ SESSION
$_SESSION['studentID'] = $student['studentID'];
$_SESSION['firstname'] = $student['firstname'];
$_SESSION['lastname']  = $student['lastname'];
$_SESSION['email']     = $student['email'];

echo json_encode([
    "status" => "success",
    "message" => "User login successfully",
    "studentID" => $student['studentID'],
    "firstname" => $student['firstname'],
    "lastname" => $student['lastname'],
    "email" => $student['email']
]);