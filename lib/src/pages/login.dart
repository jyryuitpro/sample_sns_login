import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }

  Future<UserCredential> signInWithApple() async {
    bool isAvailable = await SignInWithApple.isAvailable();
    if (isAvailable) {
      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.anomalo.snslogin.sample-sns-login.web',
          redirectUri: Uri.parse(
              'https://midnight-robust-drop.glitch.me//callbacks/sign_in_with_apple'),
        ),
      );

      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in `appleCredential.identityToken`, sign in will fail.
      return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    } else {
      final clientState = Uuid().v4();
      final url = Uri.https('appleid.apple.com', '/auth/authorize', {
        'response_type': 'code id_token',
        'client_id': "com.anomalo.snslogin.sample-sns-login.web",
        'response_mode': 'form_post',
        'redirect_uri':
            'https://midnight-robust-drop.glitch.me//callbacks/sign_in_with_apple',
        'scope': 'email name',
        'state': clientState,
      });

      final result = await FlutterWebAuth.authenticate(
          url: url.toString(), callbackUrlScheme: "applink");

      final body = Uri.parse(result).queryParameters;
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: body['id_token'],
        accessToken: body['code'],
      );
      return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Firebase SNS Login'),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlatButton(
              color: Colors.grey.withOpacity(0.3),
              child: Text('Google Login'),
              onPressed: signInWithGoogle,
            ),
            FlatButton(
              color: Colors.grey.withOpacity(0.3),
              child: Text('Facebook Login'),
              onPressed: signInWithFacebook,
            ),
            FlatButton(
              color: Colors.grey.withOpacity(0.3),
              child: Text('Apple Login'),
              onPressed: signInWithFacebook,
            ),
          ],
        ),
      ),
    );
  }
}
