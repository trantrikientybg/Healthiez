# Walkthrough - OAuth Username Initialization & Forgot Password Fixes

We have implemented automatic `username` generation for OAuth logins (Google & Facebook) matching your exact rules, alongside the complete Forgot Password flow and email configuration.

---

## 1. Quy tắc Tự động Khởi tạo Username cho Đăng nhập Mạng xã hội (OAuth)

Hàm `ensureOAuthUsernameCreated` trong `AuthRepository` & `AuthService` đã được bổ sung và tự động kích hoạt mỗi khi người dùng đăng nhập qua Google hoặc Facebook:

### **Quy tắc tạo Username**:
1. **Đăng nhập bằng Google (`google`)**:
   - Định dạng: `gg_<phần trước @ của mail google>`
   - Ví dụ: Email `john.smith@gmail.com` -> Username: `gg_john.smith`
2. **Đăng nhập bằng Facebook (`facebook`)**:
   - Định dạng: `fb_<id facebook của tài khoản>`
   - Ví dụ: ID Facebook `102234567890123` -> Username: `fb_102234567890123`
   - *(Ứng dụng trích xuất ID Facebook từ `userMetadata['provider_id']`, `userMetadata['sub']`, hoặc danh sách `user.identities`)*.

---

## 2. Các bước cấu hình Email OTP Đặt lại mật khẩu trên Supabase

Dành cho phần gửi mã xác minh OTP Đặt lại mật khẩu:

1. **Custom SMTP**: Trong **Project Settings** -> **Authentication** -> **SMTP Settings**, đảm bảo **Enable Custom SMTP** đã được bật (ON) với thông tin Email Support của bạn.
2. **Email Template**: Trong **Authentication** -> **Email Templates** -> **Reset password**:
   - Sử dụng mã HTML tại tệp [`supabase/email_templates/reset_password_otp.html`](file:///C:/Users/24h/AndroidStudioProjects/healthiez/supabase/email_templates/reset_password_otp.html).
   - Đảm bảo mẫu dùng biến `{{ .Token }}` và không chứa `{{ .ConfirmationURL }}`.

---

## 3. Kết quả Kiểm thử

- **Static Analysis**: `flutter analyze` -> **0 lỗi**.
- **Unit & Widget Tests**: `flutter test` -> **10/10 tests thành công**.
