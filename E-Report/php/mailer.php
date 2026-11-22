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

// Helper function to configure SMTP settings
function configureSMTP($mail) {
    $mail->SMTPDebug = SMTP::DEBUG_OFF;
    $mail->isSMTP();
    $mail->Host       = 'smtp.gmail.com';
    $mail->SMTPAuth   = true;
    $mail->Username   = 'lambunaoolgu@gmail.com';    // Your Gmail address
    $mail->Password   = 'asifavvfapppejqm';          // Your Gmail App Password
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = 587;
}

/**
 * Get user and report info from database
 */
function getReportInfo($reportID) {
    // Create new connection for this function
    $host = 'localhost'; 
    $dbname = 'ereport';
    $username = 'root';
    $password = '';
    
    try {
        $conn = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        error_log("Database connection failed: " . $e->getMessage());
        return null;
    }
    
    // First, try to get report with user join
    $sql = "SELECT u.email, u.firstname as user_firstname, u.lastname as user_lastname, 
                   r.firstname, r.lastname, r.category, r.description, r.location, r.timestamp, r.userID
            FROM reports r 
            LEFT JOIN users u ON r.userID = u.userID 
            WHERE r.reportID = :reportID";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':reportID', $reportID);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$result) {
        return null;
    }
    
    // If we have user email from join, use it
    if (!empty($result['email'])) {
        return [
            'email' => $result['email'],
            'firstname' => $result['user_firstname'],
            'lastname' => $result['user_lastname'],
            'category' => $result['category'],
            'description' => $result['description'],
            'location' => $result['location'],
            'timestamp' => $result['timestamp']
        ];
    }
    
    // If no userID match, try to find user by firstname/lastname in reports
    if (!empty($result['firstname']) && !empty($result['lastname'])) {
        $sql2 = "SELECT * FROM users WHERE firstname = :firstname AND lastname = :lastname LIMIT 1";
        $stmt2 = $conn->prepare($sql2);
        $stmt2->bindParam(':firstname', $result['firstname']);
        $stmt2->bindParam(':lastname', $result['lastname']);
        $stmt2->execute();
        $user = $stmt2->fetch(PDO::FETCH_ASSOC);
        
        if ($user && !empty($user['email'])) {
            return [
                'email' => $user['email'],
                'firstname' => $user['firstname'],
                'lastname' => $user['lastname'],
                'category' => $result['category'],
                'description' => $result['description'],
                'location' => $result['location'],
                'timestamp' => $result['timestamp']
            ];
        }
    }
    
    // If still no email, try getting any user with matching name
    if (!empty($result['firstname'])) {
        $sql3 = "SELECT * FROM users WHERE firstname LIKE :firstname LIMIT 1";
        $stmt3 = $conn->prepare($sql3);
        $likeName = '%' . $result['firstname'] . '%';
        $stmt3->bindParam(':firstname', $likeName);
        $stmt3->execute();
        $user = $stmt3->fetch(PDO::FETCH_ASSOC);
        
        if ($user && !empty($user['email'])) {
            return [
                'email' => $user['email'],
                'firstname' => $user['firstname'],
                'lastname' => $user['lastname'],
                'category' => $result['category'],
                'description' => $result['description'],
                'location' => $result['location'],
                'timestamp' => $result['timestamp']
            ];
        }
    }
    
    return null;
}

/**
 * Send status update notification email to the user
 * 
 * @param int $reportID The report ID
 * @param string $status The new status (in-progress, rejected, resolved)
 * @return array Status and message
 */
function sendStatusNotification($reportID, $status) {
    $mail = new PHPMailer(true);
    
    try {
        // Get report and user info
        $reportInfo = getReportInfo($reportID);
        
        if (!$reportInfo) {
            return ['status' => 'error', 'message' => 'Report not found'];
        }
        
        $toEmail = $reportInfo['email'];
        $toName = $reportInfo['firstname'] . ' ' . $reportInfo['lastname'];
        $category = $reportInfo['category'];
        $description = $reportInfo['description'];
        $location = $reportInfo['location'];
        $reportDate = $reportInfo['timestamp'];
        
        // Validate that we have a valid email recipient
        if (empty($toEmail)) {
            return ['status' => 'error', 'message' => 'No user email found for this report'];
        }
        
        // Configure SMTP
        configureSMTP($mail);
        
        // Recipients
        $mail->setFrom('lawrencepoblacion@gmail.com', 'E-Report System');
        $mail->addAddress($toEmail, $toName);
        
        // Content - Customize message based on status
        $mail->isHTML(true);
        
        if ($status === 'in-progress') {
            $mail->Subject = 'Your Report is Now In Progress - E-Report System';
            $mail->Body    = "<h3 style='color: #0dcaf0;'>Your Report is In Progress</h3>
                              <p>Dear <strong>$toName</strong>,</p>
                              <p>We are writing to inform you that your community report status has been updated to <strong style='color: #0dcaf0;'>IN PROGRESS</strong>.</p>
                              <hr>
                              <h4>Report Details:</h4>
                              <table style='width: 100%; border-collapse: collapse;'>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Report ID:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$reportID</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Category:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$category</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Description:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$description</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Location:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$location</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Submitted Date:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$reportDate</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Current Status:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><span style='color: #0dcaf0; font-weight: bold;'>IN PROGRESS</span></td>
                                  </tr>
                              </table>
                              <p>Our team is actively working on addressing your concern. We will notify you once the issue has been resolved.</p>
                              <p>Thank you for your patience.</p>
                              <p>Best regards,<br><strong>E-Report System</strong><br>Municipality of Lambunao</p>";
            $mail->AltBody = "Your Report (#$reportID) Status: IN PROGRESS - Category: $category, Location: $location - The admin is working on your report.";
        } elseif ($status === 'rejected') {
            $mail->Subject = 'Your Report Has Been Rejected - E-Report System';
            $mail->Body    = "<h3 style='color: #dc3545;'>Your Report Has Been Rejected</h3>
                              <p>Dear <strong>$toName</strong>,</p>
                              <p>We regret to inform you that your community report has been <strong style='color: #dc3545;'>REJECTED</strong>.</p>
                              <hr>
                              <h4>Report Details:</h4>
                              <table style='width: 100%; border-collapse: collapse;'>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Report ID:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$reportID</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Category:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$category</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Description:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$description</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Location:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$location</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Submitted Date:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$reportDate</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Current Status:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><span style='color: #dc3545; font-weight: bold;'>REJECTED</span></td>
                                  </tr>
                              </table>
                              <p>If you believe this is an error or would like to submit a new report, please contact us.</p>
                              <p>Thank you for your understanding.</p>
                              <p>Best regards,<br><strong>E-Report System</strong><br>Municipality of Lambunao</p>";
            $mail->AltBody = "Your Report (#$reportID) Status: REJECTED - Category: $category, Location: $location - Your report was not approved.";
        } elseif ($status === 'resolved') {
            $mail->Subject = 'Your Report Has Been Resolved - E-Report System';
            $mail->Body    = "<h3 style='color: #198754;'>Your Report Has Been Resolved</h3>
                              <p>Dear <strong>$toName</strong>,</p>
                              <p>We are pleased to inform you that your community report has been <strong style='color: #198754;'>RESOLVED</strong>.</p>
                              <hr>
                              <h4>Report Details:</h4>
                              <table style='width: 100%; border-collapse: collapse;'>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Report ID:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$reportID</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Category:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$category</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Description:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$description</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Location:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$location</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Submitted Date:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'>$reportDate</td>
                                  </tr>
                                  <tr>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><strong>Current Status:</strong></td>
                                      <td style='padding: 8px; border: 1px solid #ddd;'><span style='color: #198754; font-weight: bold;'>RESOLVED</span></td>
                                  </tr>
                              </table>
                              <p>Thank you for bringing this matter to our attention. We appreciate your patience and cooperation.</p>
                              <p>Best regards,<br><strong>E-Report System</strong><br>Municipality of Lambunao</p>";
            $mail->AltBody = "Your Report (#$reportID) Status: RESOLVED - Category: $category, Location: $location - Your report has been addressed and resolved.";
        } else {
            return ['status' => 'error', 'message' => 'Invalid status'];
        }
        
        $mail->send();
        
        return ['status' => 'success', 'message' => 'Email notification sent to ' . $toEmail];
        
    } catch (Exception $e) {
        return ['status' => 'error', 'message' => "Email failed: {$mail->ErrorInfo}"];
    }
}

?>

