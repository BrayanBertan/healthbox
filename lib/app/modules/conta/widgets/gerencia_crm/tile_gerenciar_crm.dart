import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/modules/conta/controller.dart';
import 'package:healthbox/app/modules/conta/widgets/gerencia_crm/barra_novo_crm.dart';
import 'package:healthbox/app/modules/conta/widgets/gerencia_crm/crm_detalhes_dialog.dart';

class TileGerenciarCrm extends GetView<ContaController> {
  const TileGerenciarCrm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ExpansionTile(
        leading: const Icon(Icons.document_scanner),
        title: const Text('Gerenciar CRM'),
        children: [
          controller.crmId == null ? BarraNovoCrm() : Container(),
          Container(
            height: MediaQuery.of(context).size.height * 0.15,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Obx(
              () => controller.crms.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.crms.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(
                            '${controller.crms[index].crm} ${controller.crms[index].estado_sigla}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  controller
                                      .setCrmEdicao(controller.crms[index]);
                                  FocusScope.of(context).unfocus();
                                  await showDialog(
                                          context: context,
                                          builder: (_) => DialogDetalhesCrm())
                                      .then((retorno) {
                                    controller.crmId = null;
                                    controller.crmController.clear();
                                    controller.crm = null;
                                    controller.crmuf = 'SC';
                                    controller.crmErroMensagem = null;
                                    controller.atualizaUsuarioCrms();
                                  });
                                },
                                icon: const Icon(Icons.edit),
                                color: Colors.yellow,
                              ),
                              IconButton(
                                onPressed: controller.crms.length <= 1
                                    ? null
                                    : () => controller.deletarCrm(
                                        controller.crms[index].id!,
                                        '${controller.crms[index].crm} ${controller.crms[index].estado_sigla}'),
                                icon: const Icon(Icons.delete_forever),
                                color: Colors.redAccent,
                              )
                            ],
                          ),
                        );
                      },
                    )
                  : const Text('Você não possui nenhum crm'),
            ),
          )
        ],
      ),
    );
  }
}
