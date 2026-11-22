<?php
session_start();

$studentID = $_SESSION['studentID'];
$email = $_SESSION['email'] ?? '';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment - West Visayas State University</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
    <script type="text/javascript"
        src="https://cdn.jsdelivr.net/npm/@emailjs/browser@4/dist/email.min.js">
    </script>
    <script type="text/javascript">
    (function(){
        emailjs.init({
            publicKey: "T2-O08LqLsASP4BDY",
        });
    })();
    </script>
    <script src="../js/script.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Roboto+Slab:wght@100..900&display=swap');
        body {
            background: linear-gradient(to top, rgb(128, 5, 118) 0%, rgb(252, 192, 206) 100%);
            min-height: 100vh;
        }
        .payment-card {
            max-width: 650px;
            margin: 50px auto;
        }
        .notification-toast {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
            min-width: 300px;
        }
    </style>
</head>
<body>
<nav class="navbar m-0 p-0">
    <div class="container-fluid">
        <a class="navbar-brand fw-bold" href="#" style="font-family: 'Roboto Slab', serif;">
            <img src="../image/west.png" alt="Logo" width="50" height="50" class="d-inline-block align-text-center">
            West Visayas State University - Lambunao Campus
        </a>
        <div>
            <a href="studentinfo.php" class="btn btn-dark btn-sm me-2">
                <i class="bi bi-person"></i> Profile
            </a>
            <!-- <a href="logout.php" class="btn btn-outline-danger btn-sm">
                <i class="bi bi-box-arrow-right"></i> Logout
            </a> -->
        </div>
    </div>
</nav>

<div class="container">
    <div class="payment-card d-flex justify-content-center align-items-center">
        <div class="col card shadow">
            <div class="card-header bg-white">
                <h4 class="mb-0"><i class="bi bi-credit-card"></i> Payment Form</h4>
            </div>
            <div class="card-body">
                <form id="paymentForm" onsubmit="pay(event)" autocomplete="off">

                    <!-- session values (not sent, just for display/debug if needed) -->
                    <input type="hidden" id="studentID" value="<?php echo htmlspecialchars($studentID); ?>">
                    <input type="hidden" id="email" value="<?php echo htmlspecialchars($email); ?>">

                    <div class="row">
                        <div class="col-md-12 mb-3">
                            <label for="displayEmail" class="form-label">Email</label>
                            <input type="email" class="form-control" id="displayEmail"
                                   value="<?php echo htmlspecialchars($email); ?>" readonly>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="scholarship" class="form-label">Scholarship</label>
                            <select class="form-select" id="scholarship" name="scholarship" required>
                                <option value="" selected disabled>Select scholarship</option>
                                <option value="Free Higher Education">Free Higher Education</option>
                                <option value="CHED Scholarship">CHED Scholarship</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label for="paymentMethod" class="form-label">Payment Method</label>
                            <select class="form-select" id="paymentMethod" name="paymentMethod" required>
                                <option value="" selected disabled>Select Payment Method</option>
                                <option value="Full Payment">Full Payment</option>
                            </select>
                        </div>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary btn-z flex-grow-1" id="submitBtn">
                            <i class="bi bi-check-circle"></i> Pay Now
                        </button>
                        <button type="reset" class="btn btn-outline-secondary btn-lg">
                            <i class="bi bi-x-circle"></i> Clear
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<!-- Loading Spinner -->
<div class="modal fade" id="loadingModal" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-body text-center py-4">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
                <p class="mt-2">Processing your payment...</p>
            </div>
        </div>
    </div>
</div>

<script src="../js/index.js"></script>
<script src="../js/jquery.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>