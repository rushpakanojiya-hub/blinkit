import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBrandGreen = Color(0xFF0C831F);

enum LegalDocType { terms, privacy }

class LegalScreen extends StatelessWidget {
  final LegalDocType type;

  const LegalScreen({super.key, required this.type});

  String get _title =>
      type == LegalDocType.terms ? 'Terms of Service' : 'Privacy Policy';

  String get _body => type == LegalDocType.terms ? _termsText : _privacyText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: Text(
          _title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            _body,
            style: GoogleFonts.poppins(
              fontSize: 18,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

const String _termsText = '''
Last Updated: August 2026

Acceptance of Terms
Thank you for using GOfresh. These Terms & Conditions ("Terms") govern your access to and use of the GOfresh mobile application, website, platform and related services (collectively referred to as the "GOfresh Platform"). By accessing or using the GOfresh Platform, placing an order, purchasing products, or using any service provided through the platform, you agree to be bound by these Terms and the GOfresh Privacy Policy. If you do not agree with these Terms, you should not access or use the GOfresh Platform or its Services. GOfresh may update or modify these Terms from time to time. Updated Terms will be made available through the GOfresh Platform and will become effective upon publication unless otherwise specified.

Services
GOfresh is a technology-enabled platform that allows users to browse, purchase and receive products offered through the GOfresh Platform. Products may be supplied by GOfresh, its affiliates, partner stores, sellers, merchants or other third-party service providers ("Third-Party Sellers"). The availability of products and delivery services may vary depending on the user's location. GOfresh may add, modify, suspend or discontinue any Service or feature of the platform at any time, subject to applicable law.

Eligibility
You must be legally competent to enter into a contract under applicable Indian law to use the GOfresh Platform. Users below 18 years of age may use the platform only under the supervision of a parent or legal guardian who is legally competent to enter into these Terms. Users must not purchase products that are prohibited for minors under applicable law. The GOfresh Platform is primarily intended for personal and household consumption. Business-to-business or resale use may be restricted unless specifically permitted by GOfresh.

Account & Registration
Certain features and services may require you to create an account. You agree to provide accurate, complete and up-to-date information while registering and using your GOfresh account. You are responsible for maintaining the confidentiality of your account credentials and for all activities carried out through your account. You must immediately notify GOfresh if you believe that your account has been accessed or used without authorization. By registering your mobile number or other contact details, you consent to receive transactional communications relating to orders, payments, delivery, customer support and other service-related updates. Promotional communications may be managed through the preferences or opt-out options provided by GOfresh.

Orders
You may place orders for available products through the GOfresh Platform. An order placed by you constitutes a request to purchase the selected products. GOfresh may accept, reject or cancel an order in accordance with these Terms and applicable policies. Product availability, prices, delivery charges, applicable taxes, offers and estimated delivery times may change from time to time. GOfresh may cancel or restrict an order in cases including product unavailability, pricing errors, suspected fraud, incorrect information, operational limitations or other legitimate reasons.

Payments
Payments may be made using the payment methods made available on the GOfresh Platform. You agree to provide valid and accurate payment information when making a purchase. Payment processing may be handled through authorized third-party payment service providers. GOfresh does not store sensitive payment information except as permitted or required under applicable law and its Privacy Policy.

Cancellation, Returns & Refunds
Orders may be cancelled, returned or refunded only in accordance with the applicable cancellation, return and refund policies displayed on the GOfresh Platform. Refunds, where applicable, may be processed to the original payment method or through another method permitted by GOfresh. Certain products may not be eligible for return or cancellation because of their nature, applicable law, hygiene requirements, perishability or other restrictions.

Limited Licence
Subject to these Terms, GOfresh grants you a limited, personal, non-exclusive, non-transferable and revocable licence to access and use the GOfresh Platform for lawful personal use. You must not: copy or reproduce the GOfresh Platform without permission; modify or create derivative works from the platform; use the platform for unauthorized commercial purposes; use automated systems, bots, scraping tools or data-mining technologies without authorization; attempt to gain unauthorized access to the platform or its systems; reverse engineer, decompile or disassemble the application; or circumvent security or access-control mechanisms.

Prohibited Content & Activities
You must not use the GOfresh Platform to upload, transmit, publish or communicate content that violates applicable law; is fraudulent, misleading, defamatory, abusive, threatening or unlawful; infringes intellectual-property rights; impersonates another person or organization; contains malicious software, viruses or harmful code; attempts to compromise the security of the GOfresh Platform; involves unauthorized access to another user's account or information; promotes illegal activities; contains spam or deceptive advertising; attempts to manipulate reviews, ratings or feedback; or otherwise violates these Terms or applicable law.

Reviews & User Content
Users may be permitted to submit reviews, ratings, comments or other content through the GOfresh Platform. You are responsible for ensuring that any content submitted by you is accurate, lawful and does not infringe the rights of any third party. GOfresh may remove or restrict content that violates these Terms or applicable law.

Third-Party Sellers & Services
Some products or services may be provided by third-party sellers, merchants or service providers. Where applicable, transactions involving third-party sellers may be subject to additional terms and conditions. GOfresh may act as a technology platform or facilitator for such transactions and may not control every aspect of products or services supplied by third parties.

Advertising & Promotions
The GOfresh Platform may contain advertisements, promotional offers, brand campaigns, contests or other promotional activities. Additional terms may apply to specific offers, discounts, contests or campaigns. GOfresh may modify or withdraw promotional offers subject to the applicable terms and conditions.

Intellectual Property
All trademarks, logos, designs, text, graphics, software, content and other materials available through the GOfresh Platform are owned by or licensed to GOfresh or the applicable rights holders. You may not copy, reproduce, distribute, modify or commercially exploit such materials without prior written authorization.

Disclaimers
The GOfresh Platform and Services are provided on an "as is" and "as available" basis to the fullest extent permitted by applicable law. GOfresh does not guarantee that the platform will always be uninterrupted, error-free, secure or completely accurate. To the extent permitted by law, GOfresh shall not be responsible for losses arising from circumstances beyond its reasonable control, including third-party service interruptions, network failures, technical issues or events beyond GOfresh's control.

Limitation of Liability
To the maximum extent permitted by applicable law, GOfresh and its affiliates, officers, employees, agents and service providers shall not be liable for indirect, incidental, special or consequential losses arising from your use of the GOfresh Platform or Services. Nothing in these Terms excludes or limits liability that cannot legally be excluded or limited under applicable law.

Suspension or Termination
GOfresh may suspend, restrict or terminate your access to the GOfresh Platform where reasonably necessary, including where you violate these Terms, engage in fraudulent activity, misuse the platform or otherwise act unlawfully. You may stop using the GOfresh Platform at any time.

Governing Law
These Terms shall be governed by and interpreted in accordance with the applicable laws of India. Any disputes arising in connection with these Terms or the GOfresh Platform shall be subject to the jurisdiction of the courts having appropriate jurisdiction, subject to applicable law.

Changes to These Terms
GOfresh may revise these Terms from time to time. The updated version will be published on the GOfresh Platform with the applicable "Last Updated" date. Your continued use of the GOfresh Platform after the updated Terms become effective constitutes acceptance of the revised Terms.

Contact Us
If you have questions, complaints or requests relating to these Terms, please contact GOfresh through the customer-support/contact details provided within the GOfresh Platform.

GOfresh
Email: xyz@gmail.com
Website: Gofresh.com
Registered Office: VASHI
''';

const String _privacyText = '''
Last Updated: August 2026

Privacy
Your use of the GOfresh Platform is also governed by this Privacy Policy.

GOfresh may collect and process information necessary to provide its services, process orders, facilitate payments, communicate with users, provide customer support, prevent fraud and improve the platform, subject to applicable law.

Contact Us
If you have questions, complaints or requests relating to this Privacy Policy, please contact GOfresh through the customer-support/contact details provided within the GOfresh Platform.

GOfresh
Email: xyz@gmail.com
Website: Gofresh.com
Registered Office: VASHI
''';


