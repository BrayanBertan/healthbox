import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/data/enums/tipo_usuario.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/controller.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/widgets/login_redirect.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/widgets/step0.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/widgets/step1.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/widgets/step2.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/widgets/step3_medico.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/widgets/step3_paciente.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/widgets/step4.dart';
import 'package:healthbox/app/widgets/notificacoes/custom_appbar.dart';

import '../../../../core/theme/app_colors.dart';

class DadosUsuarioPage extends GetView<DadosUsuarioController> {
  const DadosUsuarioPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: controller.isEditing
          ? CustomAppBar(title: 'Editar')
          : AppBar(
              title: const Text('Cadastro'),
            ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Container(
                  width: constraints.maxWidth,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Obx(() {
                    return Stepper(
                      currentStep: controller.activeStepIndex,
                      type: StepperType.horizontal,
                      steps: <Step>[
                        Step(
                            title: Text(''),
                            content: Step0Page(),
                            isActive: controller.activeStepIndex == 0,
                            state: controller.getStepState(0)),
                        Step(
                            title: Text(''),
                            content: Step1Page(),
                            isActive: controller.activeStepIndex == 1,
                            state: controller.getStepState(1)),
                        Step(
                            title: Text(''),
                            content: Step2Page(),
                            isActive: controller.activeStepIndex == 2,
                            state: controller.getStepState(2)),
                        Step(
                            title: Text(''),
                            content: controller.tipo == TipoUsuario.PACIENTE
                                ? Step3PacientePage()
                                : Step3MedicoPage(),
                            isActive: controller.activeStepIndex == 3,
                            state: controller.getStepState(3)),
                        Step(
                            title: Text(''),
                            content: Step4Page(),
                            isActive: controller.activeStepIndex == 4,
                            state: controller.getStepState(4)),
                      ],
                      onStepCancel: controller.activeStepIndexDecrease,
                      onStepContinue: controller.activeStepIndexIncrease,
                      onStepTapped: (int step) {
                        FocusScope.of(context).unfocus();
                        controller.setActiveStepIndex(step, context: context);
                      },
                      controlsBuilder:
                          (BuildContext context, ControlsDetails details) {
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Obx(() => ElevatedButton(
                                  onPressed: controller.activeStepIndex < 1
                                      ? null
                                      : details.onStepCancel,
                                  style: ElevatedButton.styleFrom(
                                      onSurface: corPrincipal300,
                                      fixedSize: const Size(150, 50)),
                                  child: const Text('Anterior'))),
                              Obx(() => ElevatedButton(
                                  onPressed: controller.activeStepIndex > 4 ||
                                          !controller.isValidStep(
                                              controller.activeStepIndex)
                                      ? null
                                      : () {
                                          controller
                                              .requestFirstFieldFocus(context);
                                          if (controller.activeStepIndex == 4) {
                                            controller.salvarUsuario();
                                            return;
                                          }
                                          details.onStepContinue!();
                                        },
                                  style: ElevatedButton.styleFrom(
                                      onSurface: corPrincipal300,
                                      fixedSize: const Size(150, 50)),
                                  child: Text(controller.activeStepIndex == 4
                                      ? 'Confirmar?'
                                      : 'Próximo'))),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),
            controller.isEditing ? Container() : const LoginRedirect()
          ],
        ),
      ),
    );
  }
}
