<?php
/**
 * Test EmailJS Integration
 * This file can be used to test if EmailJS is working correctly
 */

include 'mailer.php';

// Test data
$testEmail = 'test@example.com';
$testName = 'Test User';
$testSubjectName = 'Test Subject';
$testSubjectCode = 'TS001';

echo "Testing EmailJS Integration...\n";
echo "==============================\n\n";

$result = sendPaymentNotification($testEmail, $testName, $testSubjectName, $testSubjectCode);

echo "Result:\n";
print_r($result);

echo "\n";
if ($result['status'] === 'success') {
    echo "✓ Email sent successfully!\n";
    echo "Note: Check the recipient's email inbox (including spam folder)\n";
} else {
    echo "✗ Email failed: " . $result['message'] . "\n";
}
?>
