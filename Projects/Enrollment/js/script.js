// EmailJS Configuration and Payment Email Function

// Send payment confirmation email using EmailJS
function sendMail() {
    // Get form values
    const studentID = document.getElementById('studentID').value;
    const email = document.getElementById('email').value;
    const scholarship = document.getElementById('scholarship').value;
    const paymentMethod = document.getElementById('paymentMethod').value;

    // Validate required fields
    if (!email || !scholarship || !paymentMethod) {
        showNotification('Please fill in all required fields', 'danger');
        return false;
    }

    // Prepare email parameters
    let params = {
        to_email: email,
        student_id: studentID,
        scholarship: scholarship,
        payment_method: paymentMethod,
        payment_status: 'Pending',
        message: `Payment submitted for scholarship: ${scholarship}, Payment Method: ${paymentMethod}`
    };

    // Show loading state
    const submitBtn = document.getElementById('submitBtn');
    const originalBtnText = submitBtn.innerHTML;
    submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Processing...';
    submitBtn.disabled = true;

    // Send email using EmailJS
    // Note: Replace with your actual EmailJS service ID and template ID
    emailjs.send("service_9h8l7qj", "template_1g5m9s8", params)
        .then(function(response) {
            console.log('SUCCESS!', response.status, response.text);
            showNotification('Payment confirmation email sent successfully!', 'success');
            
            // Reset form after successful submission
            setTimeout(() => {
                document.getElementById('paymentForm').reset();
            }, 2000);
        })
        .catch(function(error) {
            console.log('FAILED...', error);
            showNotification('Failed to send email. Please try again.', 'danger');
        })
        .finally(function() {
            // Restore button state
            submitBtn.innerHTML = originalBtnText;
            submitBtn.disabled = false;
        });

    return false; // Prevent form submission
}

// Function to show notification toast
function showNotification(message, type) {
    // Remove existing notification if any
    const existingToast = document.querySelector('.notification-toast');
    if (existingToast) {
        existingToast.remove();
    }

    // Create toast element
    const toast = document.createElement('div');
    toast.className = `notification-toast alert alert-${type} alert-dismissible fade show`;
    toast.setAttribute('role', 'alert');
    toast.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;

    // Add to body
    document.body.appendChild(toast);

    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 5000);
}

// Pay function - handles form submission
function pay(event) {
    event.preventDefault();
    
    // Validate form
    const form = document.getElementById('paymentForm');
    if (!form.checkValidity()) {
        form.reportValidity();
        return false;
    }

    // Show loading modal
    const loadingModal = new bootstrap.Modal(document.getElementById('loadingModal'));
    loadingModal.show();

    // Send email
    sendMail();

    // Hide loading modal after a short delay
    setTimeout(() => {
        loadingModal.hide();
    }, 2000);

    return false;
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', function() {
    console.log('Payment form initialized with EmailJS');
});

