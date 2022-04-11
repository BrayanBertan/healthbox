import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/data/models/medicamento.dart';
import 'package:healthbox/app/data/models/medicamento_info.dart';
import 'package:healthbox/app/data/models/opiniao.dart';
import 'package:healthbox/app/data/repositories/tratamento.dart';
import 'package:healthbox/app/modules/opinioes/controller.dart';
import 'package:healthbox/core/theme/easy_loading_config.dart';
import 'package:healthbox/routes/app_pages.dart';

import '../login/controller.dart';

class PostarTratamentoController extends GetxController {
  final TratamentoRepository repository;
  dynamic usuario;
  final loginController = Get.find<LoginController>();
  PostarTratamentoController({required this.repository})
      : assert(repository != null) {
    usuario = loginController.getLogin();
    doc = Document()..insert(0, ' ');
  }

  @override
  void onInit() {
    super.onInit();
  }

  //======================TODOS==========================================
  final _activeStepIndex = 0.obs;
  get activeStepIndex => this._activeStepIndex.value;
  setActiveStepIndex(value) => this._activeStepIndex.value =
      isValidStep(activeStepIndex) || value < activeStepIndex
          ? value
          : activeStepIndex;
  activeStepIndexIncrease() => this._activeStepIndex.value++;
  activeStepIndexDecrease() => this._activeStepIndex.value--;

  bool isValidStep(int step) {
    bool retorno = false;
    switch (step) {
      case 0:
        retorno = step1Valido();
        break;
      default:
        retorno = step1Valido();
    }
    return retorno;
  }

  StepState getStepState(int step) {
    if (step == activeStepIndex) return StepState.editing;
    if (step != activeStepIndex && isValidStep(step)) return StepState.complete;
    if (step != activeStepIndex && !isValidStep(step)) return StepState.indexed;
    return StepState.indexed;
  }

//===============================STEP 1==================================
  final _doc = Rx<Document>(Document()..insert(0, ' '));
  final _texto = Rx<String?>(null);
  final _titulo = Rx<String?>(null);
  final _idOpiniao = Rx<int?>(null);
  final _carregando = false.obs;
  final _eficacia = 1.obs;
  QuillController controller_editor = QuillController.basic();
  final eficazList = <Map<String, dynamic>>[
    {'titulo': 'Eficaz', 'valor': 1},
    {'titulo': 'Ineficaz', 'valor': 0}
  ];
  get idOpiniao => this._idOpiniao.value;
  set idOpiniao(value) => this._idOpiniao.value = value;
  get doc => this._doc.value;
  set doc(value) => this._doc.value = value;
  get titulo => this._titulo.value;
  setTitulo(value) => this._titulo.value = value;
  get texto => this._texto.value;
  set texto(value) => this._texto.value = value;
  get carregando => this._carregando.value;
  set carregando(value) => this._carregando.value = value;
  get eficacia => this._eficacia.value;
  setEficacia(value) => this._eficacia.value = value;
  get editorLength =>
      controller_editor.document.toDelta().toJson()[0]['insert'].length;

  bool step1Valido() => textoValido() && tituloValido();

  bool tituloValido() =>
      titulo != null && editorLength > 10 && editorLength <= 200;

  String? get tituloErroMensagem {
    if (titulo == null || tituloValido()) return null;
    return 'Campo obrigatório';
  }

  bool textoValido() =>
      texto != null && editorLength > 10 && editorLength <= 200;

  String? get textoErroMensagem {
    if (texto == null || textoValido()) return null;
    if (editorLength > 200) return 'Descrição muito longa';
    return 'Descrição muito curta';
  }

  //===============================STEP 2==================================

  final medicamentosSelecionados = <Medicamento>[].obs;
  final medicamentosSelecionadosInfo = <MedicamentoInfo>[].obs;
  Future<List<Medicamento>> getMedicamentos(String? filtro) async {
    if (filtro == null) return List<Medicamento>.empty();
    return await repository.getMedicamentosFiltro(filtro);
  }

  setOpiniaoEdicao(Opiniao opiniao) {
    if (opiniao.pacienteId != usuario.id) {
      Get.offNamed(Routes.INITIAL);
      return;
    }
    idOpiniao = opiniao.id;
    texto = opiniao.descricao;
    doc = Document.fromJson(jsonDecode(texto));
    setEficacia(opiniao.eficaz);
  }

  salvarOpiniao() {
    texto = jsonEncode(controller_editor.document.toDelta().toJson());

    Opiniao opiniao = Opiniao(
        id: idOpiniao,
        descricao: texto,
        pacienteId: usuario.id,
        eficaz: eficacia,
        ativo: 1);
    repository.salvarOpiniao(opiniao).then((retorno) {
      if (retorno) {
        EasyLoading.showSuccess('Opinião salva com sucesso');
        redirectListagem();
      } else {
        EasyLoading.instance.backgroundColor = Colors.red;
        EasyLoading.showError('Erro ao salvar opinião');
        EasyLoadingConfig();
      }
    });
  }

  deletarOpiniao() {
    repository.deletarOpiniao(idOpiniao).then((retorno) {
      if (retorno) {
        EasyLoading.showToast('Opinião deletada com sucesso',
            toastPosition: EasyLoadingToastPosition.bottom);
        redirectListagem();
      } else {
        EasyLoading.showToast('Erro ao deletar  Opinião',
            toastPosition: EasyLoadingToastPosition.bottom);
      }
    });
  }

  redirectListagem() {
    Get.find<OpinioesController>().getOpinioes();
    Get.offNamed(Routes.INITIAL);
  }
}
