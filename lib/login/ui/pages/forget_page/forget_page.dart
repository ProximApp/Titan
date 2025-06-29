import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/login/providers/sign_up_provider.dart';
import 'package:titan/login/router.dart';
import 'package:titan/login/tools/constants.dart';
import 'package:titan/login/ui/auth_page.dart';
import 'package:titan/login/ui/components/sign_in_up_bar.dart';
import 'package:titan/login/ui/components/text_from_decoration.dart';
import 'package:titan/tools/functions.dart';
import 'package:qlevar_router/qlevar_router.dart';

class ForgetPassword extends HookConsumerWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signUpNotifier = ref.watch(signUpProvider.notifier);
    final email = useTextEditingController();
    void displayToastWithContext(TypeMsg type, String msg) {
      displayToast(context, type, msg);
    }

    return LoginTemplate(
      callback: (AnimationController controller) {
        if (!controller.isCompleted) {
          controller.forward();
        }
      },
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    QR.to(LoginRouter.root);
                  },
                  child: const HeroIcon(
                    HeroIcons.chevronLeft,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LoginTextConstants.forgetPassword,
                    style: GoogleFonts.elMessiri(
                      textStyle: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: AutofillGroup(
                        child: TextFormField(
                          controller: email,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          decoration: signInRegisterInputDecoration(
                            isSignIn: false,
                            hintText: LoginTextConstants.email,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SignInUpBar(
                      label: LoginTextConstants.recover,
                      isLoading: ref
                          .watch(loadingProvider)
                          .maybeWhen(data: (data) => data, orElse: () => false),
                      onPressed: () async {
                        final value = await signUpNotifier.recoverUser(
                          email.text,
                        );
                        if (value) {
                          displayToastWithContext(
                            TypeMsg.msg,
                            LoginTextConstants.sendedResetMail,
                          );
                          email.clear();
                          QR.to(
                            LoginRouter.forgotPassword +
                                LoginRouter.mailReceived,
                          );
                        } else {
                          displayToastWithContext(
                            TypeMsg.error,
                            LoginTextConstants.mailSendingError,
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 40,
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            splashColor: const Color.fromRGBO(255, 255, 255, 1),
                            onTap: () {
                              QR.to(LoginRouter.root);
                            },
                            child: const Text(
                              LoginTextConstants.signIn,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            splashColor: const Color.fromRGBO(255, 255, 255, 1),
                            onTap: () {
                              QR.to(
                                LoginRouter.forgotPassword +
                                    LoginRouter.mailReceived,
                              );
                            },
                            child: const Text(
                              LoginTextConstants.recievedMail,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
