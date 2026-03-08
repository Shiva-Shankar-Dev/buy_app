# Privacy Policy & Data Safety Content

This document provides the content you need for your app's Privacy Policy website and the answers for the Google Play Console "Data safety" section.

---

## Part 1: Privacy Policy Content

**Instructions:** Create a page on your website (e.g., `https://your-domain.com/privacy-policy`) and paste the following content. Replace placeholders like Buy_App and `[Date]` with your actual values.

***

# Privacy Policy for Buy App

**Last Updated:** 31st January 2026

**Buy App** ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share your personal information when you use our mobile application **Buy App** (the "App").

By using the App, you agree to the collection and use of information in accordance with this policy.

### 1. Information We Collect

We collect the following types of information to provide and improve our App:

*   **Personal Information:** When you create an account or place an order, we collect personal details such as:
    *   Name
    *   Email address
    *   Phone number
    *   Shipping address
*   **Financial Information:** We process payments through secure third-party payment processors (Razorpay). We do not store your credit card details or full bank account numbers on our servers. We only retain transaction IDs and payment status.
*   **App Activity:** We collect information about how you interact with the App, such as:
    *   Product views
    *   Search history
    *   Order history
    *   Wishlist items
    *   Comments and reviews
*   **Device Information:** We may collect device-specific information such as your device model, operating system version, and unique device identifiers to ensure App compatibility and security.

### 2. How We Use Your Information

We use the collected information for the following purposes:

*   **Service Delivery:** To create your account, process your orders, and deliver products to you.
*   **Communication:** To send you order updates, transaction receipts, and customer support responses.
*   **Security:** To detect and prevent fraud, unauthorized access, and other security issues.
*   **App Improvement:** To analyze usage patterns and improve user experience.

### 3. Data Sharing and Third Parties

We do not sell your personal data. We share data only with the following trusted third-party service providers to facilitate App functionality:

*   **Google Firebase:** Used for authentication, database storage, and backend services.
*   **Razorpay:** Used to process secure payments.
*   **Logistics Providers:** Your shipping address and contact details are shared with delivery partners to fulfill your orders.

### 4. Data Security

We implement reasonable security measures to protect your data, including encryption in transit (HTTPS) and secure storage on Google Cloud Platform (Firestore). Access to personal data is restricted to authorized personnel and systems.

### 5. Data Retention and Deletion

We retain your personal data as long as your account is active or as needed to provide you services.

**Requesting Data Deletion:**
If you wish to delete your account and associated data, please contact our support team at **support@buyapp.com**. We will process your request within 30 days, subject to legal retention requirements (e.g., transaction records for tax purposes).

### 6. Children's Privacy

Our App is not intended for use by children under the age of 13. We do not knowingly collect personal information from children.

### 7. Changes to This Policy

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.

### 8. Contact Us

If you have any questions about this Privacy Policy, please contact us at:
*   **Email:** support@buyapp.com
*   **Phone:** +91 12345 67890

---

## Part 2: Google Play Data Safety Answers

**Instructions:** Use these answers when filling out the "Data safety" form in the Google Play Console > App Content.

### 1. Data Collection and Security
*   **Does your app collect or share any of the required user data types?** -> **Yes**
*   **Is all of the user data collected by your app encrypted in transit?** -> **Yes** (https/ssl is standard for Firebase/Razorpay)
*   **Do you provide a way for users to request that their data be deleted?** -> **Yes** (Select "Users can request deletion via email/website link" if you don't have an in-app button yet)

### 2. Data Types

Select the following categories and specific data types:

**Category: Personal Info**
*   **Name**: Collected (App functionality, Account management)
*   **Email Address**: Collected (App functionality, Account management)
*   **Address**: Collected (App functionality - Shipping)
*   **Phone Number**: Collected (App functionality - Contact/Delivery)

**Category: Financial Info**
*   **Purchase History**: Collected (App functionality)
*   *Note: Credit Card info is handled by Razorpay, you typically select "Collected" but mark it as processed by a third party payment processor.*

**Category: Device or other IDs**
*   **Device or other IDs**: Collected (App functionality, Analytics/Fraud prevention - Firebase Auth usually uses some identifiers)

### 3. Usage and Handling (for each selected type)
For most items (Name, Email, Address, Phone):
*   **Is this data collected, shared, or both?** -> **Collected** (and **Shared** if you count Delivery partners as "Sharing" - usually Service Providers for fulfillment are considered part of the service, but payment processors are often considered "Sharing" or "Collected" depending on integration. Safe bet: **Collected**).
*   **Is this data processed ephemerally?** -> **No**
*   **Is this data required for your app?** -> **Yes** (Users cannot use the app without it)
*   **Why is this user data collected?** -> Select: **App functionality**, **Account management**. 

For **Purchase History**:
*   **Why is this user data collected?** -> **App functionality**, **Fraud prevention**.

---

### Tips for "Delete Account" Requirement
Google Play now mandates that if you allow account creation, you **must** provide a web link to request account deletion.
*   **Web Link:** Ensure the `Privacy Policy` page or a dedicated `Contact/Support` page on your website mentions how to delete the account (e.g., "Email us at support@buyapp.com").
