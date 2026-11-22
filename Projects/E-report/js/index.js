function signup(e) {
    e.preventDefault();
    var lastname = $("#lastname").val();
    var firstname = $("#firstname").val();
    var middlename = $("#middlename").val();
    var address = $("#address").val();
    var contactnumber = $("#contactnumber").val();
    var email = $("#signup-email").val();
    var password = $("#signup-password").val();
    $.post("./php/signup.php", {
        lastname: lastname,
        firstname: firstname,
        middlename: middlename,
        address: address,
        contactnumber: contactnumber,
        email: email,
        password: password
    }, function (data) {
        console.log(data)
        let dataX = (typeof data === "string") ? JSON.parse(data) : data
        if (dataX.status == "success") {
            alert("Registration Successful!")
            window.location.href = "ereport.php"
        } else {
            alert("Registration error!")
        }
    }).fail(function(xhr, status, error) {
        alert("Error: " + error);
    });
    return false;
}

function login(e) {
    e.preventDefault();
    var email = $("#email").val();
    var password = $("#password").val();
    $.post("./php/login.php", {
        email: email,
        password: password
    }, function (data) {
        console.log("Server response:", data)
        let dataX = (typeof data === "string") ? JSON.parse(data) : data
        if (dataX.status == "success") {
            // Check email directly in JavaScript as primary check
            var redirectUrl = "ereport.php";
            if (email.toLowerCase() === "admin@gmail.com") {
                redirectUrl = "admin.php";
            } else if (dataX.redirect) {
                // Fallback to server response
                redirectUrl = dataX.redirect;
            }
            
            console.log("Redirecting to:", redirectUrl);
            window.location.href = redirectUrl
        } else {
            alert(dataX.message || "Invalid email or password!")
        }
    }).fail(function(xhr, status, error) {
        alert("Error: " + error);
    });
    return false;
}

function report(e) {
    e.preventDefault();
    var formData = new FormData();
    var category = $("#category").val();
    if (category === "Others") {
        category = $("#otherCategory").val();
    }
    formData.append("category", category);
    formData.append("description", $("#description").val());
    formData.append("location", $("#location").val());
    var lat = $("#latitude").val();
    var lng = $("#longitude").val();
    
    // Fallback to Lambunao defaults if coordinates are missing for any reason
    if (!lat || !lng) {
        lat = 11.0506;
        lng = 122.4764;
        $("#latitude").val(lat);
        $("#longitude").val(lng);
    }
    formData.append("latitude", lat);
    formData.append("longitude", lng);
    
    // Check if file is selected
    var fileInput = $("#photo")[0];
    console.log("File input:", fileInput);
    console.log("Files:", fileInput.files);
    
    if (fileInput.files.length > 0) {
        formData.append("photo", fileInput.files[0]);
        console.log("Adding photo to formData:", fileInput.files[0].name);
    } else {
        console.log("No file selected");
    }
    
    $.ajax({
        url: "./php/report.php",
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
        success: function(data) {
            console.log("Server response:", data);
            // Safely parse — jQuery may have already parsed JSON
            var dataX;
            try {
                dataX = (typeof data === "string") ? JSON.parse(data) : data;
            } catch (e) {
                console.error("JSON parse error:", e);
                alert("Unexpected server response.");
                return;
            }

            if (dataX.status == "success") {
                alert("Report Successful!");

                // Reset all form fields
                $("#reportForm")[0].reset();

                // Trigger change on category so dependent UI (e.g., Others box) updates
                $("#category").trigger("change");

                // Defensive cleanup of dependent / dynamic UI elements
                $("#otherCategoryDiv").hide();
                $("#otherCategory").prop("required", false);
                $("#geotagStatus").removeClass("success warning info").css("display", "none").empty();

                // Hide pin map and pin coords
                $("#pinMapWrapper").hide();
                $("#pinCoords").hide();

                // Remove pin marker from map if it exists
                if (typeof pinMarker !== "undefined" && pinMarker) {
                    pinMarker.remove();
                    pinMarker = null;
                }

                // Re-fill coordinates so the next report doesn't fail
                const defaultLat = 11.0506;
                const defaultLng = 122.4764;
                $("#latitude").val(defaultLat);
                $("#longitude").val(defaultLng);

                loadUserReports(); // Reload the reports list
            } else {
                alert("Report error: " + (dataX.message || "Unknown error"));
            }
        },
        error: function(xhr, status, error) {
            alert("Error: " + error);
            console.log("Error details:", xhr, status, error);
        }
    });
    return false;
}