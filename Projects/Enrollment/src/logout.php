<?php
session_start();
session_destroy();
?>
<script>
    localStorage.removeItem("session");
    window.location.href = "./index.php";
</script>
