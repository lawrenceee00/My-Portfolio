<?php
session_start();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Information</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Archivo+Black&family=Bebas+Neue&family=Lobster+Two:ital,wght@0,400;0,700;1,400;1,700&family=Roboto+Slab:wght@100..900&family=Tapestry&display=swap');
        body {
            background: linear-gradient(to top, rgb(128, 5, 118) 0%, rgb(252, 192, 206) 100%);
            min-height: 100vh;
        }
    </style>
</head>
<body>
    <nav class="navbar m-0 p-0">
        <div class="container-fluid">
            <a class="navbar-brand fw-bold" href="#"  style="font-family: 'Roboto Slab', serif;">
                <img src="../image/west.png" alt="Logo" width="50" height="50" class="d-inline-block align-text-center">
                West Visayas State University - Lambunao Campus
            </a>
            <div>
                <a href="ereport.php" class="btn btn-sm btn-dark">Enroll a Subject</a>
                <!-- <a href="logout.php" class="btn btn-outline-danger btn-sm">
                    <i class="bi bi-box-arrow-right"></i> Logout
                </a> -->
            </div>
        </div>
    </nav>

    <div class="container py-4">
        <div class="card shadow">
            <div class="card-body">
                <h4 class="mb-3">Student Information</h4>
                <form id="studentInfoForm" autocomplete="off">
                    <div class="row g-3">
                        <div class="col-md-3">
                            <label class="form-label">Last Name</label>
                            <input type="text" class="form-control" id="lastname" readonly>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">First Name</label>
                            <input type="text" class="form-control" id="firstname" readonly>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Middle Name</label>
                            <input type="text" class="form-control" id="middlename" readonly>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Birthday</label>
                            <input type="text" class="form-control" id="birthday" readonly>
                        </div>
                        <div class="col-md-12">
                            <label class="form-label">Address</label>
                            <input type="text" class="form-control" id="address" readonly>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Contact Number</label>
                            <input type="text" class="form-control" id="contactnumber" readonly>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Gender</label>
                             <select class="form-select" id="gender" name="gender" readonly>
                                <option value="" selected disabled>Select Gender</option>
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Semester</label>
                            <select class="form-select" id="semester" name="semester" readonly>
                                <option value="" selected disabled>Select Semester</option>
                                <option value="1st Semester">1st Semester</option>
                                <option value="2nd Semester">2nd Semester</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Year</label>
                            <select class="form-select" id="year" name="year" readonly>
                                <option value="" selected disabled>Select Year</option>
                                <option value="1st Year">1st Year</option>
                                <option value="2nd Year">2nd Year</option>
                                <option value="3rd Year">3rd Year</option>
                                <option value="4th Year">4th Year</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Course</label>
                            <select class="form-select" id="course" name="course" readonly>
                                <option value="" selected disabled>Select Course</option>
                                <option value="BS in Hospitality Management">BS in Hospitality Management</option>
                                <option value="BS in Information Communication Technology">BS in Information Communication Technology</option>
                                <option value="BS in Industrial Technology">BS in Industrial Technology</option>
                                <option value="Bachelor of Elementary Education">Bachelor of Elementary Education</option>
                                <option value="Bachelor of Secondary Education">Bachelor of Secondary Education</option>
                                <option value="BS in Criminology">BS in Criminology</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Email</label>
                            <input type="text" class="form-control" id="email" readonly>
                        </div>
                        <div class="col-md-12 mt-4">
                            <button type="button" class="btn btn-primary" id="editBtn">Edit</button>
                            <button type="button" class="btn btn-success d-none" id="saveBtn">Save</button>
                            <button type="button" class="btn btn-secondary d-none" id="cancelBtn">Cancel</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="../js/jquery.js"></script>
    <script>
        $(function () {
            const studentID = $("#studentID").val();
            let originalData = {};

            $.post("../php/info.php", { studentID: studentID }, function (rawData) {
                let response;
                try {
                    response = typeof rawData === "string" ? JSON.parse(rawData) : rawData;
                } catch (e) {
                    alert("Invalid response from server.");
                    return;
                }

                if (response.status !== "success") {
                    alert(response.message || "Failed to load student information.");
                    return;
                }

                const student = response.data || {};
                originalData = { ...student };
                
                // Initialize select fields as disabled (read-only)
                $("#gender, #semester, #year, #course").prop("disabled", true);
                
                $("#view-studentID").val(student.studentID || "");
                $("#lastname").val(student.lastname || "");
                $("#firstname").val(student.firstname || "");
                $("#middlename").val(student.middlename || "");
                $("#address").val(student.address || "");
                $("#contactnumber").val(student.contactnumber || "");
                $("#birthday").val(student.birthday || "");
                $("#gender").val(student.gender || "");
                $("#semester").val(student.semester || "");
                $("#year").val(student.year || "");
                $("#course").val(student.course || "");
                $("#email").val(student.email || "");
            }).fail(function () {
                alert("Could not connect to the server.");
            });

            // Edit button click handler
            $("#editBtn").click(function () {
                $("#studentInfoForm input").removeAttr("readonly");
                // Enable select fields for gender, semester, year, and course
                $("#gender, #semester, #year, #course").prop("disabled", false);
                $("#editBtn").addClass("d-none");
                $("#saveBtn").removeClass("d-none");
                $("#cancelBtn").removeClass("d-none");
            });

            // Cancel button click handler
            $("#cancelBtn").click(function () {
                $("#studentInfoForm input").attr("readonly", true);
                // Disable select fields
                $("#gender, #semester, #year, #course").prop("disabled", true);
                $("#editBtn").removeClass("d-none");
                $("#saveBtn").addClass("d-none");
                $("#cancelBtn").addClass("d-none");
                
                // Restore original values
                $("#lastname").val(originalData.lastname || "");
                $("#firstname").val(originalData.firstname || "");
                $("#middlename").val(originalData.middlename || "");
                $("#address").val(originalData.address || "");
                $("#contactnumber").val(originalData.contactnumber || "");
                $("#birthday").val(originalData.birthday || "");
                $("#gender").val(originalData.gender || "");
                $("#semester").val(originalData.semester || "");
                $("#year").val(originalData.year || "");
                $("#course").val(originalData.course || "");
                $("#email").val(originalData.email || "");
            });

            // Save button click handler
            $("#saveBtn").click(function () {
                const formData = {
                    action: "update",
                    lastname: $("#lastname").val(),
                    firstname: $("#firstname").val(),
                    middlename: $("#middlename").val(),
                    address: $("#address").val(),
                    contactnumber: $("#contactnumber").val(),
                    birthday: $("#birthday").val(),
                    gender: $("#gender").val(),
                    semester: $("#semester").val(),
                    year: $("#year").val(),
                    course: $("#course").val(),
                    email: $("#email").val()
                };

                $.post("../php/info.php", formData, function (rawData) {
                    let response;
                    try {
                        response = typeof rawData === "string" ? JSON.parse(rawData) : rawData;
                    } catch (e) {
                        alert("Invalid response from server.");
                        return;
                    }

                    if (response.status === "success") {
                        alert(response.message || "Student information updated successfully!");
                        originalData = { ...formData };
                        $("#studentInfoForm input").attr("readonly", true);
                        // Disable select fields back to read-only
                        $("#gender, #semester, #year, #course").prop("disabled", true);
                        $("#editBtn").removeClass("d-none");
                        $("#saveBtn").addClass("d-none");
                        $("#cancelBtn").addClass("d-none");
                    } else {
                        alert(response.message || "Failed to update student information.");
                    }
                }).fail(function () {
                    alert("Could not connect to the server.");
                });
            });
        });
    </script>
</body>
</html>
