import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/data/enums/tipo_usuario.dart';
import 'package:healthbox/app/data/models/medicamento.dart';
import 'package:healthbox/app/modules/graficos/controller.dart';
import 'package:healthbox/app/modules/graficos/widgets/shimmer_graficos_filtro.dart';
import 'package:healthbox/core/theme/app_colors.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class CardFiltro extends GetView<GraficosOpinioesController> {
  const CardFiltro({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Obx(() => controller.carregandoMedicamentos
          ? const ShimmerGraficosFiltro()
          : Column(
              children: [
                MultiSelectDialogField<Medicamento?>(
                    decoration: BoxDecoration(
                      color: corPrincipal,
                    ),
                    buttonText: const Text(
                        'Clique aqui para selecionar os medicamentos'),
                    confirmText: const Text('Confirmar'),
                    cancelText: const Text('Cancelar'),
                    buttonIcon: const Icon(Icons.list),
                    initialValue: controller.medicamentosSelecionados,
                    title: const Text('Medicamentos'),
                    searchable: true,
                    searchHint: 'Pesquisar',
                    dialogHeight: MediaQuery.of(context).size.height * 0.3,
                    chipDisplay: MultiSelectChipDisplay(
                      scroll: true,
                      items: controller.medicamentosSelecionados
                          .map((medicamento) => MultiSelectItem<Medicamento?>(
                              medicamento,
                              '${medicamento.nome} (${medicamento.fabricante})'))
                          .toList(),
                    ),
                    onConfirm: (items) => controller.setMedicamentos(items),
                    separateSelectedItems: true,
                    items: controller.medicamentos
                        .map((medicamento) => MultiSelectItem<Medicamento?>(
                            medicamento,
                            '${medicamento.nome} (${medicamento.fabricante})'))
                        .toList()),
                controller.usuario.tipo == TipoUsuario.MEDICO
                    ? Row(
                        children: [
                          Checkbox(
                            value: controller.isExercicioFisicoChecked,
                            onChanged: controller.setIsExercicioFisicoChecked,
                          ),
                          const Text(
                              'Filtrar por pacientes que fizeram exercício físico?')
                        ],
                      )
                    : Container()
              ],
            )),
    );
  }
}
