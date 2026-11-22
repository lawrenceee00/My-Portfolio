function signup(e) {
  e.preventDefault();

  $.post("../php/signin.php", {
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
    email: $("#signup-email").val(),
    password: $("#signup-password").val()   // ✅ CHANGED
  }, function (data) {
    let dataX = (typeof data === "string") ? JSON.parse(data) : data;  // ✅ CHANGED

    if (dataX.status === "success") {
      alert("Sign up successful!");
      window.location.href = "../src/studentinfo.php";
    } else {
      alert(dataX.message || "Sign up failed!"); // ✅ CHANGED
    }
  }).fail(function () {
    alert("Server error during signup.");
  });
}

function login(e) {
  e.preventDefault();

  $.post("../php/login.php", {
    email: $("#login-email").val(),
    password: $("#login-password").val()    // ✅ CHANGED
  }, function (data) {
    let dataX = (typeof data === "string") ? JSON.parse(data) : data;  // ✅ CHANGED

    if (dataX.status === "success") {
      alert("Login successful!");
      window.location.href = "../src/studentinfo.php";
    } else {
      alert(dataX.message || "Login failed!"); // ✅ CHANGED
    }
  }).fail(function () {
    alert("Server error during login.");
  });
}

function subject(e) {
  e.preventDefault();

  $("#spinnerOverlay").removeClass("d-none").addClass("d-flex");

  $.post("../php/subject.php", {
    subjectName: $("#subjectName").val(),
    subjectCode: $("#subjectCode").val()
  }, function (data) {
    $("#spinnerOverlay").removeClass("d-flex").addClass("d-none");

    let dataX = (typeof data === "string") ? JSON.parse(data) : data; // ✅ CHANGED

    if (dataX.status === "success") {
      alert("Subject enrolled successfully!, Proceed to payment to complete the enrollment process.");
      window.location.href = "../src/payment.php";
    } else {
      alert(dataX.message || "Failed to enroll subject!"); // ✅ CHANGED
    }
  }).fail(function () {
    $("#spinnerOverlay").removeClass("d-flex").addClass("d-none");
    alert("Server error enrolling subject.");
  });
}
function pay(e) {
  e.preventDefault();
    var email = $("#email").val();
    var scholarship = $("#scholarship").val();
    var paymentMethod = $("#paymentMethod").val();
    
    $.post("../php/pay.php", {
        email: email,
        scholarship: scholarship,
        paymentMethod: paymentMethod
    }, function(data) {
        console.log(data)
        let dataX = (typeof data === "string") ? JSON.parse(data) : data;
        
        if (dataX.status == "success") {
            alert("Payment successful! Please wait for the email notification regarding your enrollment status.");
            window.location.href = "..//index.php";
        } else {
            alert("Payment failed! " + (dataX.message || ""));
        }
    }).fail(function(xhr, status, error) {
        alert("Server error during payment. Please try again.");
    });
}

