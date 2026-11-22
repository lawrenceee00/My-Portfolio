<?php
session_start();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enrollment</title> 
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Archivo+Black&family=Bebas+Neue&family=Lobster+Two:ital,wght@0,400;0,700;1,400;1,700&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Archivo+Black&family=Bebas+Neue&family=Lobster+Two:ital,wght@0,400;0,700;1,400;1,700&family=Tapestry&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Archivo+Black&family=Bebas+Neue&family=Lobster+Two:ital,wght@0,400;0,700;1,400;1,700&family=Roboto+Slab:wght@100..900&family=Tapestry&display=swap');
        body {
            background: linear-gradient(to top, rgb(128, 5, 118) 0%, rgb(252, 192, 206) 100%);
            min-height: 100vh;
        }
        .form-toggle-btn {
            transition: all 0.3s ease;
        }
        .form-toggle-btn.active {
            background-color: #000;
            color: white;
            border-color: #000;
        }
        .form-toggle-btn:not(.active) {
            background-color: transparent;
            color: #000;
            border-color: #000;
        }
        #signup-form {
            display: none;
        }
        #login-form {
            display: block;
        }
    </style>
</head>
<body>
    <nav class="navbar m-0 p-0" style="font-weight: bold;">
        <div class="container-fluid">
            <a class="navbar-brand" href="#" style="font-family: 'Roboto Slab', serif;">
                <img src="../image/west.png" alt="Logo" width="50" height="50" class="d-inline-block align-text-center">
                West Visayas State University - Lambunao Campus
            </a>
            </div>
        </div>
    </nav>
    <div class="container-fluid">
        <div class="d-flex justify-content-center align-items-center mt-5">
            <div class="card overflow-hidden">
                <div class="card-header bg-white border-0">
                    <div class="d-flex justify-content-center gap-2">
                        <button type="button" class="btn form-toggle-btn active w-25" id="show-login-btn" onclick="showForm('login')"><i class="bi bi-box-arrow-in-right me-1"></i>Login</button>
                        <img src="../image/west.png" alt="Logo" width="50" height="50" class="d-inline-block align-text-center">
                        <button type="button" class="btn form-toggle-btn w-25" id="show-signup-btn" onclick="showForm('signup')"><i class="bi bi-plus-circle me-1"></i>Sign Up</button>
                    </div>
                </div>
                <hr>
                <div class="card-body pt-0 overflow-auto">
                           
                            <div id="login-form">
                                <form onsubmit="login(event)" autocomplete="on">
                                    <div class="row">
                                        <div class="col-12 mb-2">
                                            <label for="login-email" class="form-label">Email</label>
                                            <input type="email" class="form-control" id="login-email" name="email" required>
                                        </div>
                                        <div class="col-12 mb-2">
                                            <label for="login-password" class="form-label">Password</label>
                                            <div class="position-relative">
                                                <input type="password" class="form-control" id="login-password" name="password" required>
                                                <i class="bi bi-eye-slash-fill position-absolute" style="right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer;" id="toggleLoginPassword"></i>
                                            </div>
                                        </div>
                                        <div class="col-12 mt-2 d-flex justify-content-center gap-2">
                                            <button type="submit" class="btn w-100" style="background-color: #000; color: white;">Login</button>
                                        </div>
                                    </div>
                                </form>
                            </div>
                            
                            <div id="signup-form" style="max-width: 900px; width: 100%;">
                                <form onsubmit="signup(event)" autocomplete="on">
                                    <div class="row">
                                        <div class="col-3 mb-2">
                                            <label for="lastname" class="form-label">Lastname</label>
                                            <input type="text" class="form-control" id="lastname" name="lastname" required>
                                        </div>
                                        <div class="col-3 mb-2">
                                            <label for="firstname" class="form-label">Firstname</label>
                                            <input type="text" class="form-control" id="firstname" name="firstname" required>
                                        </div>
                                        <div class="col-3 mb-2">
                                            <label for="middlename" class="form-label">Middlename</label>
                                            <input type="text" class="form-control" id="middlename" name="middlename" required>
                                        </div>
                                        <div class="col-3 mb-2">
                                            <label for="birthday" class="form-label">Birthday</label>
                                            <input type="date" class="form-control" id="birthday" name="birthday" required>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <label for="address" class="form-label">Address</label>
                                            <input type="text" class="form-control" id="address" name="address" required>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <label for="contactnumber" class="form-label">Contact Number</label>
                                            <input type="text" class="form-control" id="contactnumber" name="contactnumber" required>
                                        </div>
                                        <div class="col-3 mb-2">
                                            <label for="gender" class="form-label">Gender</label>
                                            <select class="form-select" id="gender" name="gender" required>
                                                <option value="" selected disabled>Select Gender</option>
                                                <option value="Male">Male</option>
                                                <option value="Female">Female</option>
                                            </select>
                                        </div>
                                        <div class="col-3 mb-2">
                                            <label for="semester" class="form-label">Semester</label>
                                            <select class="form-select" id="semester" name="semester" required>
                                                <option value="" selected disabled>Select Semester</option>
                                                <option value="1st Semester">1st Semester</option>
                                                <option value="2nd Semester">2nd Semester</option>
                                            </select>
                                        </div>
                                        <div class="col-3 mb-2">
                                            <label for="year" class="form-label">Year</label>
                                            <select class="form-select" id="year" name="year" required>
                                                <option value="" selected disabled>Select Year</option>
                                                <option value="1st Year">1st Year</option>
                                                <option value="2nd Year">2nd Year</option>
                                                <option value="3rd Year">3rd Year</option>
                                                <option value="4th Year">4th Year</option>
                                            </select>
                                        </div>
                                        <div class="col-3 mb-2">
                                            <label for="course" class="form-label">Course</label>
                                            <select class="form-select" id="course" name="course" required>
                                                <option value="" selected disabled>Select Course</option>
                                                <option value="BS in Hospitality Management">BS in Hospitality Management</option>
                                                <option value="BS in Information Communication Technology">BS in Information Communication Technology</option>
                                                <option value="BS in Industrial Technology">BS in Industrial Technology</option>
                                                <option value="Bachelor of Elementary Education">Bachelor of Elementary Education</option>
                                                <option value="Bachelor of Secondary Education">Bachelor of Secondary Education</option>
                                                <option value="BS in Criminology">BS in Criminology</option>
                                            </select>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <label for="signup-email" class="form-label">Email</label>
                                            <input type="email" class="form-control" id="signup-email" name="email" required>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <label for="signup-password" class="form-label">Password</label>
                                            <div class="position-relative">
                                                <input type="password" class="form-control" id="signup-password" name="password" required>
                                                <i class="bi bi-eye-slash-fill position-absolute" style="right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer;" id="toggleSignupPassword"></i>
                                            </div>
                                        </div>
                                        <div class="col-12 mt-2 d-flex justify-content-center gap-2">
                                            <button type="submit" class="btn w-100" style="background-color: #000; color: white;">Sign Up</button>
                                            <button type="reset" class="btn btn-outline-secondary w-50">Cancel</button>
                                        </div>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="../js/index.js"></script>
    <script src="../js/jquery.js"></script>
    <script>
        // Toggle between Login and Sign Up forms
        function showForm(formType) {
            const loginForm = document.getElementById('login-form');
            const signupForm = document.getElementById('signup-form');
            const loginBtn = document.getElementById('show-login-btn');
            const signupBtn = document.getElementById('show-signup-btn');
            
            if (formType === 'login') {
                loginForm.style.display = 'block';
                signupForm.style.display = 'none';
                loginBtn.classList.add('active');
                signupBtn.classList.remove('active');
            } else {
                loginForm.style.display = 'none';
                signupForm.style.display = 'block';
                loginBtn.classList.remove('active');
                signupBtn.classList.add('active');
            }
        }
        
        // Toggle password visibility for login form
        const toggleLoginPassword = document.getElementById('toggleLoginPassword');
        const loginPasswordInput = document.getElementById('login-password');

        if (toggleLoginPassword && loginPasswordInput) {
            toggleLoginPassword.addEventListener('click', function() {
                const type = loginPasswordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                loginPasswordInput.setAttribute('type', type);
                this.classList.toggle('bi-eye-fill');
                this.classList.toggle('bi-eye-slash-fill');
            });
        }
        
        // Toggle password visibility for signup form
        const toggleSignupPassword = document.getElementById('toggleSignupPassword');
        const signupPasswordInput = document.getElementById('signup-password');

        if (toggleSignupPassword && signupPasswordInput) {
            toggleSignupPassword.addEventListener('click', function() {
                const type = signupPasswordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                signupPasswordInput.setAttribute('type', type);
                this.classList.toggle('bi-eye-fill');
                this.classList.toggle('bi-eye-slash-fill');
            });
        }
    </script>
</body>
</html>
