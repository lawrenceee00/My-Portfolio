<?php
/**
 * Email Notification Configuration
 * 
 * Using PHPMailer for sending emails via SMTP
 * 
 * SMTP Configuration:
 * - Host: smtp.gmail.com
 * - SMTPAuth: true
 * - Encryption: TLS
 * - Port: 587
 * - Username: lawrencepoblacion@gmail.com
 */

// Using PHPMailer
require_once __DIR__ . '/../PHPMailer/src/PHPMailer.php';
require_once __DIR__ . '/../PHPMailer/src/SMTP.php';
require_once __DIR__ . '/../PHPMailer/src/Exception.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

function sendPaymentNotification($toEmail, $toName, $subjectNames) {
    $mail = new PHPMailer(true);
    
    try {
        // SMTP Configuration
        $mail->SMTPDebug = SMTP::DEBUG_OFF;
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        $mail->Username   = 'lawrencepoblacion@gmail.com';    // Your Gmail address
        $mail->Password   = 'dqtsrcuilyjtwxum';       // Your Gmail App Password
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;
        
        // Recipients
        $mail->setFrom('lawrencepoblacion@gmail.com', 'WVSU Enrollment System');
        $mail->addAddress($toEmail, $toName);
        
        // Content
        $mail->isHTML(true);
        $mail->Subject = 'Enrollment Payment Confirmation - WVSU';
        $mail->Body    = "<h3>Payment Successful!</h3>
                          <p>Dear $toName,</p>
                          <p>Your enrollment for the following subject(s) is now CONFIRMED:</p>
                          <p><strong>$subjectNames</strong></p>
                          <p>Thank you!</p>";
        $mail->AltBody = "Payment Successful! Subject(s): $subjectNames - ENROLLED";
        
        $mail->send();
        
        return ['status' => 'success', 'message' => 'Email notification sent'];
        
    } catch (Exception $e) {
        return ['status' => 'error', 'message' => "Email failed: {$mail->ErrorInfo}"];
    }
}

?>
