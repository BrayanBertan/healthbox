import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/data/models/crm.dart';
import 'package:healthbox/app/data/models/medico.dart';
import 'package:healthbox/app/data/repositories/conta.dart';
import 'package:healthbox/app/modules/conta/dados_usuario/controller.dart';

import '../../data/models/especializacao.dart';
import '../login/controller.dart';

class ContaController extends GetxController {
  final ContaRepository repository;
  final loginController = Get.find<LoginController>();
  final dadosController = Get.find<DadosUsuarioController>();
  dynamic usuario;

  ContaController({required this.repository}) : assert(repository != null) {
    usuario = loginController.getLogin();
    if (usuario is Medico) {
      crms.clear();
      crms.assignAll(usuario.crms);
      crmController.clear();
    }
  }
  final especializacoes = <Especializacao>[].obs;
  final especializacoesCrm = <Especializacao>[].obs;

  final crms = <Crm>[].obs;
  final _buttonPressed = false.obs;
  final _loopActive = false.obs;
  final _carregandoDeleta = 0.obs;
  final _crmId = Rx<int?>(null);
  final _crm = Rx<String?>(null);
  final _crmuf = 'SC'.obs;
  final _crmErroMensagem = Rx<String?>(null);
  final _isLoading = false.obs;
  final crmController = TextEditingController();
  final _crmDescricao = ''.obs;

  get buttonPressed => this._buttonPressed.value;
  set buttonPressed(value) => this._buttonPressed.value = value;

  get crmId => this._crmId.value;
  set crmId(value) => this._crmId.value = value;

  get isLoading => this._isLoading.value;
  set isLoading(value) => this._isLoading.value = value;

  get crmErroMensagem => this._crmErroMensagem.value;
  set crmErroMensagem(value) => this._crmErroMensagem.value = value;

  get crm => this._crm.value;
  set crm(value) => this._crm.value = value;

  get crmuf => this._crmuf.value;
  set crmuf(value) => this._crmuf.value = value;

  get loopActive => this._loopActive.value;
  set loopActive(value) => this._loopActive.value = value;

  get carregandoDeleta => this._carregandoDeleta.value;
  set carregandoDeleta(value) => this._carregandoDeleta.value = value;

  get crmDescricao => this._crmDescricao.value;
  set crmDescricao(value) => this._crmDescricao.value = value;

  confirmandoDeletarConta() async {
    if (loopActive) return;

    loopActive = true;

    while (buttonPressed) {
      if (carregandoDeleta < 100) carregandoDeleta = carregandoDeleta + 10;
      await Future.delayed(const Duration(milliseconds: 300));
      if (carregandoDeleta == 100) buttonPressed = false;
    }
    if (carregandoDeleta == 100) {
      repository.deletaUsuario(usuario.id).then((retorno) {
        if (retorno) {
          loginController.logout();
        }
      });
    }
    carregandoDeleta = 0;
    loopActive = false;
  }

  setCrmEdicao(Crm crmObj) {
    crmErroMensagem = null;
    crm = crmObj.crm;
    crmuf = crmObj.estado_sigla;
    especializacoesCrm
        .assignAll(crmObj.especializacoes ?? List<Especializacao>.empty());
    crmId = crmObj.id;
    crmController.text = crmObj.crm;
    crmDescricao = '${crmObj.crm} ${crmObj.estado_sigla}';
  }

  salvarCrm() async {
    isLoading = true;
    dadosController.setCrm(crm);
    dadosController.setCrmUf(crmuf);

    if (crm == null || crm!.trim().isEmpty || crm!.trim().length < 3) {
      crmErroMensagem = 'Campo obrigatório';
      isLoading = false;
      return;
    }

    await validaCrm();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!dadosController.isCrmValid) {
      crmErroMensagem = 'Crm inválido';
      isLoading = false;
      return;
    }
    await verificaCrm();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!dadosController.crmVerifica) {
      crmErroMensagem = 'Crm em uso';
      isLoading = false;
      return;
    }
    Crm _crmObj = Crm(
      crm: crm,
      estado_sigla: crmuf,
    );
    if (crmId != null) _crmObj.id = crmId;

    repository.salvarCrm(_crmObj, usuario.id).then((retorno) {
      if (retorno) {
        EasyLoading.showToast('Crm $crm  $crmuf adicionado com sucesso',
            toastPosition: EasyLoadingToastPosition.bottom);
        crmErroMensagem = null;
        if (crmId != null) {
          crmDescricao = '${_crmObj.crm} ${_crmObj.estado_sigla}';
          crmController.text = _crmObj.crm;
          crmuf = _crmObj.estado_sigla;
        } else {
          crmController.clear();
          crmuf = 'SC';
          atualizaUsuarioCrms();
        }
      } else {
        crmErroMensagem = 'Erro ao salvar crm';
      }

      isLoading = false;
    });
  }

  verificaCrm() async {
    await dadosController.verificaCrm();
  }

  validaCrm() async {
    await dadosController.validaCRM();
  }

  deletarCrm(int crmId, String crm) {
    repository.deletaCrm(crmId).then((retorno) {
      if (retorno) {
        EasyLoading.showToast('Crm $crm deletado com sucesso',
            toastPosition: EasyLoadingToastPosition.bottom);
        atualizaUsuarioCrms();
      } else {
        EasyLoading.showToast('Erro ao deletar Crm $crm',
            toastPosition: EasyLoadingToastPosition.bottom);
      }
    });
  }

  atualizaUsuarioCrms() async {
    await loginController.getUsuario();
    usuario = loginController.getLogin();
    crms.clear();
    crms.assignAll(usuario.crms);
  }

  getEspecializacoes() {
    repository.getEspecializacoes().then((List<Especializacao>? retorno) {
      this.especializacoes.clear();
      this.especializacoes.assignAll(retorno!);
    });
  }
}
