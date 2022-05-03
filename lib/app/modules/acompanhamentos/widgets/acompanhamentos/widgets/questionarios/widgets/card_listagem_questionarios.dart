import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/data/models/questionario.dart';
import 'package:healthbox/app/modules/acompanhamentos/controller.dart';
import 'package:healthbox/app/modules/acompanhamentos/widgets/acompanhamentos/widgets/questionarios/widgets/custom_list_questionario.dart';
import 'package:healthbox/app/modules/graficos/widgets/shimmer_graficos.dart';
import 'package:healthbox/core/theme/app_text_theme.dart';
import 'package:intl/intl.dart';

class CardListagemQuestionarios extends GetView<AcompanhamentosController> {
  Questionario questionario;
  CardListagemQuestionarios({required this.questionario, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.carregando
          ? const ShimmerGraficos()
          : ListView.builder(
              shrinkWrap: true,
              physics: const ScrollPhysics(),
              itemCount: controller.questionariosSelecionados.length,
              itemBuilder: (_, index) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(controller.questionariosSelecionados[index].dataResposta!)} ${controller.getHistoricoLegenda(controller.questionariosSelecionados[index].dataResposta!)['legenda']}',
                    style: subTitulo,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: IgnorePointer(
                        ignoring: true,
                        child: CustomListQuestionario(
                            questionario:
                                controller.questionariosSelecionados[index]),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}