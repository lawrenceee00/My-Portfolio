<?php
session_start();

if (isset($_GET['logout']) && $_GET['logout'] === 'true') {
    session_destroy();
    header('Location: index.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>e-Report · Lambunao</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;0,900;1,700&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">

    <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
        --violet:    #4a2c5a;
        --violet-2:  #5e3a6b;
        --violet-3:  #7a4e8c;
        --gold:      #c8973a;
        --gold-light:#e8b86d;
        --cream:     #faf7f2;
        --cream-2:   #f0ebe2;
        --ink:       #1a1a1a;
        --ink-2:     #3d3d3d;
        --ink-3:     #7a7a7a;
        --white:     #ffffff;
        --error:     #c0392b;
        --success:   #1e7e5c;

        --font-display: 'Playfair Display', Georgia, serif;
        --font-body:    'Outfit', system-ui, sans-serif;
        --radius:       10px;
        --radius-lg:    18px;
    }

    html, body {
        height: 100%;
        font-family: var(--font-body);
        background: var(--cream);
        color: var(--ink);
    }

    /* ── SPLIT LAYOUT ── */
    .split {
        display: grid;
        grid-template-columns: 1fr 1fr;
        min-height: 100vh;
        width: 100vw;
    }

    /* ── LEFT PANEL ── */
    .panel-left {
        position: relative;
        background: var(--violet);
        display: flex;
        align-items: center;         /* vertically center the inner content */
        justify-content: center;
        padding: 48px;
        overflow: hidden;
    }

    /* Decorative geometric rings */
    .panel-left::before {
        content: '';
        position: absolute;
        width: 560px; height: 560px;
        border-radius: 50%;
        border: 1px solid rgba(200,151,58,.12);
        top: 50%; left: 50%;
        transform: translate(-50%, -50%);
        pointer-events: none;
    }
    .panel-left::after {
        content: '';
        position: absolute;
        width: 380px; height: 380px;
        border-radius: 50%;
        border: 1px solid rgba(200,151,58,.18);
        top: 50%; left: 50%;
        transform: translate(-50%, -50%);
        pointer-events: none;
    }
    .ring-3 {
        position: absolute;
        width: 200px; height: 200px;
        border-radius: 50%;
        border: 1px solid rgba(200,151,58,.28);
        top: 50%; left: 50%;
        transform: translate(-50%, -50%);
        pointer-events: none;
    }

    .grain {
        position: absolute; inset: 0;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='250' height='250'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='250' height='250' filter='url(%23n)' opacity='0.06'/%3E%3C/svg%3E");
        background-size: 250px;
        pointer-events: none;
        z-index: 0;
    }

    .seal-bg {
        position: absolute;
        width: 320px; height: 320px;
        top: 50%; left: 50%;
        transform: translate(-50%, -50%);
        object-fit: contain;
        opacity: .06;
        pointer-events: none;
        z-index: 0;
        filter: grayscale(1) brightness(3);
    }

    /* ── LEFT INNER CARD — matches right panel card height ── */
    .left-inner {
        position: relative;
        z-index: 1;
        width: 100%;
        max-width: 400px;
        display: flex;
        flex-direction: column;
        gap: 28px;
    }

    /* Brand */
    .brand {
        display: flex; align-items: center; gap: 14px;
    }
    .brand-seal {
        width: 48px; height: 48px;
        border-radius: 10px;
        object-fit: contain;
        background: rgba(255,255,255,.07);
        padding: 4px;
    }
    .brand-text { line-height: 1.25; }
    .brand-text .sup {
        font-size: 0.6rem; font-weight: 500; letter-spacing: .14em;
        text-transform: uppercase; color: var(--gold);
    }
    .brand-text .name {
        font-family: var(--font-display);
        font-size: 1.05rem; color: var(--white);
    }

    /* Hero copy */
    .hero { display: flex; flex-direction: column; }
    .hero-eyebrow {
        font-size: 0.65rem; font-weight: 600; letter-spacing: .18em;
        text-transform: uppercase; color: var(--gold);
        margin-bottom: 14px;
        display: flex; align-items: center; gap: 8px;
    }
    .hero-eyebrow::before {
        content: '';
        display: inline-block; width: 28px; height: 1px;
        background: var(--gold);
    }
    .hero-title {
        font-family: var(--font-display);
        font-size: clamp(1.8rem, 2.8vw, 2.8rem);
        font-weight: 900;
        line-height: 1.1;
        color: var(--white);
        margin-bottom: 16px;
    }
    .hero-title em {
        font-style: italic; color: var(--gold-light);
    }
    .hero-desc {
        font-size: 0.875rem; line-height: 1.65; font-weight: 300;
        color: rgba(255,255,255,.6);
        margin-bottom: 24px;
    }

    /* Feature pills */
    .features { display: flex; flex-direction: column; gap: 10px; }
    .feature {
        display: flex; align-items: center; gap: 12px;
        font-size: 0.8rem; color: rgba(255,255,255,.7);
    }
    .feature-icon {
        width: 30px; height: 30px; border-radius: 8px;
        background: rgba(200,151,58,.15);
        display: flex; align-items: center; justify-content: center;
        color: var(--gold); font-size: 0.85rem;
        flex-shrink: 0;
    }

    /* Tagline */
    .tagline {
        font-family: var(--font-display);
        font-style: italic;
        font-size: 0.82rem;
        color: rgba(255,255,255,.3);
        border-top: 1px solid rgba(255,255,255,.08);
        padding-top: 18px;
    }

    /* ── RIGHT PANEL ── */
    .panel-right {
        background: var(--cream);
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 48px;
        position: relative;
        overflow-y: auto;
    }

    .panel-right::before {
        content: '';
        position: absolute; top: 0; right: 0;
        width: 200px; height: 200px;
        background-image: radial-gradient(circle, rgba(74,44,90,.12) 1px, transparent 1px);
        background-size: 20px 20px;
        pointer-events: none;
    }

    .form-box {
        width: 100%;
        max-width: 400px;
        position: relative; z-index: 1;
        animation: fadeUp .5s ease both;
    }

    @keyframes fadeUp {
        from { opacity: 0; transform: translateY(20px); }
        to   { opacity: 1; transform: translateY(0); }
    }

    /* Tab switcher */
    .tab-row {
        display: flex;
        background: var(--cream-2);
        border-radius: var(--radius-lg);
        padding: 5px;
        margin-bottom: 28px;
        gap: 4px;
    }
    .tab-btn {
        flex: 1; padding: 10px 0;
        border: none; border-radius: calc(var(--radius-lg) - 3px);
        background: transparent;
        font-family: var(--font-body); font-size: 0.82rem; font-weight: 500;
        color: var(--ink-3); cursor: pointer;
        display: flex; align-items: center; justify-content: center; gap: 6px;
        transition: background .2s, color .2s, box-shadow .2s;
    }
    .tab-btn.active {
        background: var(--white);
        color: var(--ink);
        font-weight: 600;
        box-shadow: 0 1px 6px rgba(0,0,0,.1);
    }

    /* Form heading */
    .form-heading { margin-bottom: 22px; }
    .form-heading h2 {
        font-family: var(--font-display);
        font-size: 1.6rem; font-weight: 700;
        color: var(--violet); line-height: 1.15;
        margin-bottom: 4px;
    }
    .form-heading p { font-size: 0.8rem; color: var(--ink-3); }

    /* Inputs */
    .field { margin-bottom: 14px; }
    .field label {
        display: block; font-size: 0.72rem; font-weight: 600;
        letter-spacing: .04em; text-transform: uppercase;
        color: var(--ink-2); margin-bottom: 6px;
    }
    .field input {
        width: 100%; padding: 11px 14px;
        border: 1.5px solid var(--cream-2);
        border-radius: var(--radius);
        background: var(--white);
        font-family: var(--font-body); font-size: 0.88rem;
        color: var(--ink);
        outline: none;
        transition: border-color .2s, box-shadow .2s;
    }
    .field input:focus {
        border-color: var(--violet-3);
        box-shadow: 0 0 0 3px rgba(122,78,140,.1);
    }
    .field input::placeholder { color: #bbb; }

    /* Password wrapper */
    .pw-wrap { position: relative; }
    .pw-wrap input { padding-right: 42px; }
    .pw-toggle {
        position: absolute; right: 12px; top: 50%;
        transform: translateY(-50%);
        border: none; background: none; cursor: pointer;
        color: var(--ink-3); font-size: 0.9rem;
        transition: color .15s; padding: 0;
    }
    .pw-toggle:hover { color: var(--violet); }

    /* Grid for name fields */
    .field-grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; }
    .field-grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }

    /* Submit */
    .btn-submit {
        width: 100%; padding: 13px;
        border: none; border-radius: var(--radius);
        background: var(--violet);
        color: var(--white);
        font-family: var(--font-body); font-size: 0.88rem; font-weight: 600;
        cursor: pointer; letter-spacing: .02em;
        display: flex; align-items: center; justify-content: center; gap: 8px;
        transition: background .2s, transform .1s, box-shadow .2s;
        box-shadow: 0 4px 16px rgba(74,44,90,.25);
        margin-top: 6px;
    }
    .btn-submit:hover { background: var(--violet-2); box-shadow: 0 6px 24px rgba(74,44,90,.35); }
    .btn-submit:active { transform: scale(.99); }

    /* Reset button */
    .btn-ghost {
        width: 100%; padding: 12px;
        border: 1.5px solid var(--cream-2);
        border-radius: var(--radius);
        background: transparent;
        font-family: var(--font-body); font-size: 0.85rem; font-weight: 500;
        color: var(--ink-3); cursor: pointer;
        transition: border-color .2s, color .2s;
        margin-top: 8px;
    }
    .btn-ghost:hover { border-color: var(--ink-3); color: var(--ink); }

    /* Divider */
    .form-divider {
        height: 1px; background: var(--cream-2);
        margin: 18px 0;
    }

    /* Form panel toggle */
    #signup-form { display: none; }
    #login-form  { display: block; }

    /* ── MOBILE ── */
    @media (max-width: 800px) {
        .split { grid-template-columns: 1fr; }
        .panel-left { min-height: auto; padding: 40px 28px; }
        .left-inner { max-width: 100%; }
        .hero-title  { font-size: 1.8rem; }
        .panel-right { padding: 32px 24px; min-height: auto; }
        .field-grid-3 { grid-template-columns: 1fr; }
        .field-grid-2 { grid-template-columns: 1fr; }
    }
    </style>
</head>
<body>

<div class="split">

    <!-- ══════ LEFT PANEL ══════ -->
    <div class="panel-left">
        <div class="grain"></div>
        <div class="ring-3"></div>
        <img src="./image/lgu.png" class="seal-bg" alt="">

        <div class="left-inner">

            <!-- Brand -->
            <div class="brand">
                <img src="./image/lambunao.png" class="brand-seal" alt="Lambunao seal">
                <div class="brand-text">
                    <div class="sup">Municipality of</div>
                    <div class="name">Lambunao</div>
                </div>
            </div>

            <!-- Hero -->
            <div class="hero">
                <div class="hero-eyebrow">Community Platform</div>
                <h1 class="hero-title">
                    Report. Track.<br><em>Resolve.</em>
                </h1>
                <p class="hero-desc">
                    Help us build a safer, cleaner Lambunao. Submit community issues directly to local government — from road damage to public safety.
                </p>
                <div class="features">
                    <div class="feature">
                        <div class="feature-icon"><i class="bi bi-geo-alt-fill"></i></div>
                        GPS-tagged issue reports with photo evidence
                    </div>
                    <div class="feature">
                        <div class="feature-icon"><i class="bi bi-bell-fill"></i></div>
                        Real-time status updates on your submissions
                    </div>
                    <div class="feature">
                        <div class="feature-icon"><i class="bi bi-shield-fill"></i></div>
                        Secure, government-verified platform
                    </div>
                </div>
            </div>

            <!-- Tagline -->
            <div class="tagline">Building Better Communities Together.</div>

        </div>
    </div>

    <!-- ══════ RIGHT PANEL ══════ -->
    <div class="panel-right">
        <div class="form-box">

            <!-- Tab switcher -->
            <div class="tab-row">
                <button class="tab-btn active" id="show-login-btn" onclick="showForm('login')">
                    <i class="bi bi-box-arrow-in-right"></i> Sign In
                </button>
                <button class="tab-btn" id="show-signup-btn" onclick="showForm('signup')">
                    <i class="bi bi-person-plus"></i> Create Account
                </button>
            </div>

            <!-- ─── LOGIN FORM ─── -->
            <div id="login-form">
                <div class="form-heading">
                    <h2>Welcome back</h2>
                    <p>Sign in to manage your community reports.</p>
                </div>

                <form onsubmit="login(event)" autocomplete="on">
                    <div class="field">
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email" required>
                    </div>
                    <div class="field">
                        <label for="password">Password</label>
                        <div class="pw-wrap">
                            <input type="password" id="password" name="password" required>
                            <button type="button" class="pw-toggle" id="toggleLoginPassword" tabindex="-1">
                                <i class="bi bi-eye-slash-fill"></i>
                            </button>
                        </div>
                    </div>
                    <button type="submit" class="btn-submit">
                        <i class="bi bi-box-arrow-in-right"></i> Sign In
                    </button>
                </form>
            </div>

            <!-- ─── SIGNUP FORM ─── -->
            <div id="signup-form">
                <div class="form-heading">
                    <h2>Create account</h2>
                    <p>Join the Lambunao community platform.</p>
                </div>

                <form onsubmit="signup(event)" autocomplete="on">
                    <div class="field-grid-3">
                        <div class="field">
                            <label for="lastname">Last Name</label>
                            <input type="text" id="lastname" name="lastname" required>
                        </div>
                        <div class="field">
                            <label for="firstname">First Name</label>
                            <input type="text" id="firstname" name="firstname" required>
                        </div>
                        <div class="field">
                            <label for="middlename">Middle</label>
                            <input type="text" id="middlename" name="middlename" placeholder="(optional)">
                        </div>
                    </div>

                    <div class="field-grid-2">
                        <div class="field">
                            <label for="address">Address / Barangay</label>
                            <input type="text" id="address" name="address" required>
                        </div>
                        <div class="field">
                            <label for="contactnumber">Contact No.</label>
                            <input type="text" id="contactnumber" name="contactnumber" required>
                        </div>
                    </div>

                    <div class="form-divider"></div>

                    <div class="field">
                        <label for="signup-email">Email Address</label>
                        <input type="email" id="signup-email" name="email" required>
                    </div>

                    <div class="field">
                        <label for="signup-password">Password</label>
                        <div class="pw-wrap">
                            <input type="password" id="signup-password" name="password" placeholder="Choose a strong password" required>
                            <button type="button" class="pw-toggle" id="togglePassword" tabindex="-1">
                                <i class="bi bi-eye-slash-fill"></i>
                            </button>
                        </div>
                    </div>

                    <button type="submit" class="btn-submit">
                        <i class="bi bi-person-check-fill"></i> Create Account
                    </button>
                    <button type="reset" class="btn-ghost">Clear form</button>
                </form>
            </div>

        </div>
    </div>

</div>

<script src="js/index.js"></script>
<script src="js/jquery.js"></script>
<script>
    function showForm(type) {
        const isLogin = type === 'login';
        document.getElementById('login-form').style.display  = isLogin ? 'block' : 'none';
        document.getElementById('signup-form').style.display = isLogin ? 'none'  : 'block';
        document.getElementById('show-login-btn').classList.toggle('active',  isLogin);
        document.getElementById('show-signup-btn').classList.toggle('active', !isLogin);
    }

    function makeToggle(btnId, inputId) {
        const btn   = document.getElementById(btnId);
        const input = document.getElementById(inputId);
        if (!btn || !input) return;
        btn.addEventListener('click', function () {
            const show = input.type === 'password';
            input.type = show ? 'text' : 'password';
            this.innerHTML = show
                ? '<i class="bi bi-eye-fill"></i>'
                : '<i class="bi bi-eye-slash-fill"></i>';
        });
    }

    makeToggle('toggleLoginPassword', 'password');
    makeToggle('togglePassword', 'signup-password');
</script>
</body>
</html>