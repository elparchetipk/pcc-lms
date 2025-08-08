-- PCC LMS - Initial Data Seeds
-- Version: 2025-08-08
-- Description: Essential initial data for the platform

BEGIN;

-- =============================================================================
-- COURSE CATEGORIES
-- =============================================================================

INSERT INTO course_categories (name, slug, description, icon_url, color, sort_order) VALUES
('Programming', 'programming', 'Learn programming languages and software development', 'https://cdn.pcc-lms.com/icons/programming.svg', '#3B82F6', 1),
('Web Development', 'web-development', 'Frontend, backend, and full-stack web development', 'https://cdn.pcc-lms.com/icons/web-dev.svg', '#10B981', 2),
('Data Science', 'data-science', 'Data analysis, machine learning, and AI', 'https://cdn.pcc-lms.com/icons/data-science.svg', '#8B5CF6', 3),
('Mobile Development', 'mobile-development', 'iOS, Android, and cross-platform mobile apps', 'https://cdn.pcc-lms.com/icons/mobile.svg', '#F59E0B', 4),
('DevOps & Cloud', 'devops-cloud', 'Infrastructure, deployment, and cloud technologies', 'https://cdn.pcc-lms.com/icons/devops.svg', '#EF4444', 5),
('Design', 'design', 'UI/UX design, graphic design, and visual arts', 'https://cdn.pcc-lms.com/icons/design.svg', '#EC4899', 6),
('Business', 'business', 'Entrepreneurship, marketing, and business strategy', 'https://cdn.pcc-lms.com/icons/business.svg', '#6B7280', 7),
('Cybersecurity', 'cybersecurity', 'Information security and ethical hacking', 'https://cdn.pcc-lms.com/icons/security.svg', '#DC2626', 8);

-- =============================================================================
-- NOTIFICATION TEMPLATES
-- =============================================================================

INSERT INTO notification_templates (name, subject_template, body_template, template_type, language) VALUES
-- Welcome emails
('welcome_email', 'Welcome to PCC LMS! 🚀', 
'Hi {{first_name}},

Welcome to PCC LMS! We''re excited to have you join our learning community.

Your account has been successfully created and you can now:
• Explore our course catalog
• Enroll in courses that match your interests
• Track your learning progress
• Connect with instructors and fellow students

Get started by browsing our featured courses: {{platform_url}}/courses

Happy learning!
The PCC LMS Team', 'email', 'en'),

-- Course enrollment confirmations
('course_enrollment_success', 'Welcome to {{course_title}}! 📚', 
'Hi {{first_name}},

Great news! You''ve successfully enrolled in "{{course_title}}".

Course Details:
• Instructor: {{instructor_name}}
• Duration: {{estimated_hours}} hours
• Start Date: {{start_date}}

You can access your course materials here: {{course_url}}

If you have any questions, don''t hesitate to reach out to your instructor or our support team.

Happy learning!
The PCC LMS Team', 'email', 'en'),

-- Assignment reminders
('assignment_due_reminder', 'Assignment Due Soon: {{assignment_title}} ⏰', 
'Hi {{first_name}},

This is a friendly reminder that your assignment "{{assignment_title}}" in {{course_title}} is due in {{hours_remaining}} hours.

Assignment Details:
• Due Date: {{due_date}}
• Estimated Time: {{estimated_minutes}} minutes
• Maximum Attempts: {{max_attempts}}

Submit your assignment here: {{assignment_url}}

Good luck!
The PCC LMS Team', 'email', 'en'),

-- Course completion congratulations
('course_completion', 'Congratulations! You completed {{course_title}} 🎉', 
'Hi {{first_name}},

Congratulations! You''ve successfully completed "{{course_title}}"!

Course Summary:
• Completion Date: {{completion_date}}
• Final Grade: {{final_grade}}
• Time Spent: {{total_hours}} hours
• Lessons Completed: {{lessons_completed}}/{{total_lessons}}

{{#certificate_available}}
Your certificate is ready! Download it here: {{certificate_url}}
{{/certificate_available}}

We hope you enjoyed the course. Don''t forget to:
• Leave a review for your instructor
• Check out similar courses in our catalog
• Share your achievement on social media

Keep learning!
The PCC LMS Team', 'email', 'en'),

-- Payment confirmations
('payment_success', 'Payment Confirmation for {{course_title}} 💳', 
'Hi {{first_name}},

Thank you for your purchase! Your payment has been successfully processed.

Purchase Details:
• Course: {{course_title}}
• Amount Paid: {{currency}}{{amount}}
• Payment Method: {{payment_method}}
• Transaction ID: {{transaction_id}}
• Date: {{payment_date}}

You now have full access to the course. Start learning here: {{course_url}}

Receipt: {{receipt_url}}

Thank you for choosing PCC LMS!
The PCC LMS Team', 'email', 'en'),

-- AI Chat notifications
('ai_chat_summary', 'Your AI Learning Assistant Summary 🤖', 
'Hi {{first_name}},

Here''s a summary of your recent interactions with our AI Learning Assistant:

• Total Conversations: {{conversation_count}}
• Questions Asked: {{questions_count}}
• Topics Covered: {{topics_list}}
• Recommended Resources: {{resource_count}}

Your most recent conversation was about "{{last_topic}}" in {{course_title}}.

Continue your learning journey: {{dashboard_url}}

Happy learning!
The PCC LMS Team', 'email', 'en'),

-- Push notifications
('lesson_reminder_push', 'Continue Learning', 'You have {{pending_lessons}} lessons waiting in {{course_title}}. Keep your momentum going!', 'push', 'en'),
('assignment_due_push', 'Assignment Due', '{{assignment_title}} is due in {{hours}} hours. Don''t miss the deadline!', 'push', 'en'),
('new_course_recommendation_push', 'New Course Recommendation', 'Based on your interests, we think you''ll love "{{course_title}}"', 'push', 'en'),

-- In-app notifications
('instructor_message', 'Message from {{instructor_name}}', '{{message_content}}', 'in_app', 'en'),
('grade_released', 'Grade Available', 'Your grade for "{{assignment_title}}" has been released. Check it out!', 'in_app', 'en'),
('new_lesson_available', 'New Lesson Available', 'A new lesson "{{lesson_title}}" is now available in {{course_title}}', 'in_app', 'en');

-- =============================================================================
-- GRADE SCALES
-- =============================================================================

INSERT INTO grade_scales (name, scale_definition, is_default) VALUES
('Standard Letter Grades', '{
  "A+": {"min": 97, "max": 100, "gpa": 4.0},
  "A": {"min": 93, "max": 96, "gpa": 4.0},
  "A-": {"min": 90, "max": 92, "gpa": 3.7},
  "B+": {"min": 87, "max": 89, "gpa": 3.3},
  "B": {"min": 83, "max": 86, "gpa": 3.0},
  "B-": {"min": 80, "max": 82, "gpa": 2.7},
  "C+": {"min": 77, "max": 79, "gpa": 2.3},
  "C": {"min": 73, "max": 76, "gpa": 2.0},
  "C-": {"min": 70, "max": 72, "gpa": 1.7},
  "D": {"min": 60, "max": 69, "gpa": 1.0},
  "F": {"min": 0, "max": 59, "gpa": 0.0}
}', true),

('Pass/Fail', '{
  "Pass": {"min": 70, "max": 100, "gpa": null},
  "Fail": {"min": 0, "max": 69, "gpa": null}
}', false),

('Mastery Based', '{
  "Mastery": {"min": 85, "max": 100, "gpa": 4.0},
  "Proficient": {"min": 70, "max": 84, "gpa": 3.0},
  "Developing": {"min": 50, "max": 69, "gpa": 2.0},
  "Beginning": {"min": 0, "max": 49, "gpa": 1.0}
}', false);

-- =============================================================================
-- SYSTEM ADMIN USER
-- =============================================================================

-- Create system admin user (password should be changed immediately in production)
INSERT INTO users (email, hashed_password, first_name, last_name, role, email_verified, timezone, language) VALUES
('admin@pcc-lms.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewYFKZ8Ycz9Vj8Li', 'System', 'Administrator', 'admin', true, 'UTC', 'en');

-- Create demo instructor
INSERT INTO users (email, hashed_password, first_name, last_name, role, email_verified, bio, timezone, language) VALUES
('instructor@pcc-lms.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewYFKZ8Ycz9Vj8Li', 'Demo', 'Instructor', 'instructor', true, 'Experienced software developer and educator with 10+ years in the industry.', 'UTC', 'en');

-- Create demo student
INSERT INTO users (email, hashed_password, first_name, last_name, role, email_verified, timezone, language) VALUES
('student@pcc-lms.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewYFKZ8Ycz9Vj8Li', 'Demo', 'Student', 'student', true, 'UTC', 'en');

-- =============================================================================
-- SAMPLE COUPONS
-- =============================================================================

INSERT INTO coupons (code, name, discount_type, discount_value, max_uses, valid_from, valid_until, created_by) 
SELECT 
    'WELCOME25',
    'Welcome Discount',
    'percentage',
    25.00,
    1000,
    NOW(),
    NOW() + INTERVAL '30 days',
    user_id
FROM users WHERE email = 'admin@pcc-lms.com';

INSERT INTO coupons (code, name, discount_type, discount_value, currency, max_uses, min_order_amount_cents, valid_from, valid_until, created_by) 
SELECT 
    'SAVE50',
    'Save $50 on Premium Courses',
    'fixed_amount',
    50.00,
    'USD',
    100,
    9900, -- $99 minimum order
    NOW(),
    NOW() + INTERVAL '60 days',
    user_id
FROM users WHERE email = 'admin@pcc-lms.com';

-- =============================================================================
-- INITIAL BI METRICS SETUP
-- =============================================================================

-- Create initial cohort for tracking
INSERT INTO student_cohorts (cohort_name, cohort_type, start_date, end_date) VALUES
('Launch Cohort', 'course_launch', CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days');

COMMIT;
