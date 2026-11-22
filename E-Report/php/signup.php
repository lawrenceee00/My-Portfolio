<?php

session_start();

include 'conn.php';

$lastname = $_POST['lastname'];
$firstname = $_POST['firstname'];
$middlename = $_POST['middlename'];
$address = $_POST['address'];
$contactnumber = $_POST['contactnumber'];
$email = $_POST['email'];
$password = $_POST['password'];
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

$sql = "INSERT INTO users(lastname, firstname, middlename, address, contactnumber, email, password) 
VALUES (?, ?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bindParam(1, $lastname);
$stmt->bindParam(2, $firstname);
$stmt->bindParam(3, $middlename);
$stmt->bindParam(4, $address);
$stmt->bindParam(5, $contactnumber);
$stmt->bindParam(6, $email);
$stmt->bindParam(7, $hashed_password);

if ($stmt->execute()) {
    // Get the newly created user's ID
    $userID = $conn->lastInsertId();
    
    // Set session variables to auto-login the user
    $_SESSION['userID'] = $userID;
    $_SESSION['email'] = $email;
    $_SESSION['firstname'] = $firstname;
    $_SESSION['lastname'] = $lastname;
    
    echo json_encode([
        "status" => "success",
        "message" => "Registration successful"
    ]);
}
?>

