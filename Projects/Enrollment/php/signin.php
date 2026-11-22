<?php
session_start();
include 'conn.php';

header('Content-Type: application/json');

$lastname      = $_POST['lastname'] ?? '';
$firstname     = $_POST['firstname'] ?? '';
$middlename    = $_POST['middlename'] ?? '';
$address       = $_POST['address'] ?? '';
$contactnumber = $_POST['contactnumber'] ?? '';
$birthday      = $_POST['birthday'] ?? '';
$gender        = $_POST['gender'] ?? '';
$semester      = $_POST['semester'] ?? '';
$year          = $_POST['year'] ?? '';
$course        = $_POST['course'] ?? '';
$email         = $_POST['email'] ?? '';
$rawPass       = $_POST['password'] ?? '';

if ($email === '' || $rawPass === '') {
    echo json_encode(["status" => "error", "message" => "Email and password are required"]);
    exit;
}

$password = password_hash($rawPass, PASSWORD_DEFAULT);

// OPTIONAL: prevent duplicate email
$check = $conn->prepare("SELECT studentID FROM studentinfo WHERE email = ?");
$check->execute([$email]);
if ($check->rowCount() > 0) {
    echo json_encode(["status" => "error", "message" => "Email already exists"]);
    exit;
}

$sql = "INSERT INTO studentinfo(lastname, firstname, middlename, address, contactnumber, birthday, gender, semester, year, course, email, password)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

$ok = $stmt->execute([
    $lastname, $firstname, $middlename, $address, $contactnumber,
    $birthday, $gender, $semester, $year, $course, $email, $password
]);

if ($ok) {
    $studentID = $conn->lastInsertId();

    // ✅ SESSION
    $_SESSION['studentID'] = $studentID;
    $_SESSION['firstname'] = $firstname;
    $_SESSION['lastname']  = $lastname;
    $_SESSION['email']     = $email;

    echo json_encode([
        "status" => "success",
        "message" => "User registered successfully",
        "studentID" => $studentID,
        "firstname" => $firstname,
        "lastname" => $lastname,
        "email" => $email
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Failed to register user"]);
}