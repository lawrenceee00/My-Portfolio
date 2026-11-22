<?php
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Subject Enrollment</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>
        @import url('https://fonts.googleapis.com/css2?family=Archivo+Black&family=Bebas+Neue&family=Lobster+Two:ital,wght@0,400;0,700;1,400;1,700&family=Roboto+Slab:wght@100..900&family=Tapestry&display=swap');
    body {
        background: linear-gradient(to top, rgb(128, 5, 118) 0%, rgb(252, 192, 206) 100%);
        min-height: 100vh;
    }
    .navbar-brand {
        font-weight: bold;
        color: black !important;
    }

    .card {
        border-radius: 15px;
    }

    .btn-primary {
        background-color: #0d6efd;
    }

    .status-badge {
        font-size: 0.85rem;
    }
    
    .user-avatar {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background-color: #000;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        font-size: 14px;
    }
    </style>
</head>
<body>

<!-- Navbar -->
    <nav class="navbar" style="margin: 0; padding: 0;">
            <div class="container-fluid">
                <a class="navbar-brand" href="#"  style="font-family: 'Roboto Slab', serif;">
                <img src="../image/west.png" alt="Logo" width="50" height="50" class="d-inline-block align-text-center">
                    West Visayas State University - Lambunao Campus
                </a>
                <a href="studentinfo.php" class="btn btn-sm btn-dark">Back</a>
            </div>
        </nav>
    <!-- Spinner Overlay -->
    <div id="spinnerOverlay" class="position-fixed top-0 start-0 w-100 h-100 bg-dark bg-opacity-50 d-none justify-content-center align-items-center" style="z-index: 9999;">
        <div class="text-center">
            <div class="spinner-border text-light" role="status" style="width: 4rem; height: 4rem;">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="text-light mt-3 fw-bold">Processing enrollment...</p>
        </div>
    </div>

    <div class="container mt-5">
        <div class="card shadow p-4 mb-4">
            <h4 class="mb-3">Enroll a Subject</h4>
            <hr>
            <form id="subjectForm" onsubmit="subject(event)" autocomplete="off">
                <div class="mb-3">
                    <label for="subjectName" class="form-label">Subject Name</label>
                    <input type="text" class="form-control" id="subjectName" name="subjectName" placeholder="Enter subject name" required>
                </div>
                <div class="mb-3">
                    <label for="subjectCode" class="form-label">Subject Code</label>
                    <input type="text" class="form-control" id="subjectCode" name="subjectCode" placeholder="Enter subject code" required>
                </div>
                <button type="submit" class="btn btn-dark" id="enrollBtn">Enroll Subject</button>
            </form>
        </div>
    </div>
    <script src="../js/index.js"></script>
    <script src="../js/jquery.js"></script>
</body>
</html>
