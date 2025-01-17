import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/data/enums/genero.dart';
import 'package:healthbox/app/data/enums/tipo_usuario.dart';
import 'package:healthbox/app/data/models/crm.dart';
import 'package:healthbox/app/data/models/especializacao.dart';
import 'package:healthbox/app/data/models/medico.dart';
import 'package:healthbox/app/data/models/paciente.dart';
import 'package:healthbox/app/data/repositories/usuario.dart';
import 'package:healthbox/app/modules/login/controller.dart';
import 'package:healthbox/core/extensions/validacoes.dart';
import 'package:healthbox/routes/app_pages.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

import '../../../../core/theme/easy_loading_config.dart';

class DadosUsuarioController extends GetxController {
  final UsuarioRepository repository;
  final loginController = Get.find<LoginController>();
  dynamic usuario;
  DadosUsuarioController({required this.repository})
      : assert(repository != null) {
    usuario = loginController.getLogin();
    if (usuario != null) {
      isEditing = true;
      _id.value = usuario.id;
      setTipo(usuario.tipo);
      setNome(usuario.nome);
      senhaTemp = loginController.senha;
      dataNascimento = usuario.dataNascimento;
      foto = usuario.fotoPath;
      setEmail(usuario.email);
      setTelefone(usuario.telefone);
      setGenero(usuario.genero);
      nomeController.text = nome;
      telefoneController.text = telefone;
      if (usuario is Paciente) {
        setCpf(usuario.cpf.trim());
        cpfTemp = usuario.cpf.trim();
        setAltura(usuario.altura);
        setPeso(usuario.peso);
        setComorbidades(usuario.comorbidades);
        setAlergiasMedicamentosas(usuario.alergiasMedicamentosas);
        setPredisposicaoGenetica(usuario.preDisposicaoGenetica);
      } else {
        setDescricao(usuario.descricao);
        descricaoController.text = descricao;
        setCrm(usuario.crms[0].crm);
        setCrmUf(usuario.crms[0].estado_sigla);
        setEspecializacoes(usuario.crms[0].especializacoes);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();

    getEspecializacoes();
    interval(_crm, (val) async {
      await verificaCrm();
      //validaCRM();
    }, time: const Duration(milliseconds: 1000));
    interval(_crmUf, (val) async {
      await verificaCrm();
      //validaCRM();
    }, time: const Duration(milliseconds: 1000));

    interval(_email, (val) => verificaEmail(),
        time: const Duration(milliseconds: 1000));
    interval(_cpf, (val) => verificaCpf(),
        time: const Duration(milliseconds: 1000));
  }

//===============Todos===================
  //=====Variaveis=====
  final _id = Rx<int?>(null);
  final _activeStepIndex = 0.obs;
  final _validStep = false.obs;
  final _isEditing = false.obs;
  String cpfTemp = '';
  String senhaTemp = '';
  //=====Getters e Setters=====
  get activeStepIndex => this._activeStepIndex.value;
  setActiveStepIndex(value, {BuildContext? context}) {
    if (value > activeStepIndex && context != null) {
      requestFirstFieldFocus(context);
    }
    this._activeStepIndex.value =
        isValidStep(activeStepIndex) || value < activeStepIndex
            ? value
            : activeStepIndex;
  }

  activeStepIndexIncrease() => this._activeStepIndex.value++;
  activeStepIndexDecrease() => this._activeStepIndex.value--;
  get validStep => this._validStep.value;
  set validStep(value) => this._validStep.value = value;
  get isEditing => this._isEditing.value;
  set isEditing(value) => this._isEditing.value = value;
  //=====Validações=====
  bool step0Valido() {
    if (tipo == TipoUsuario.PACIENTE && cpfValido()) return true;
    if (tipo == TipoUsuario.MEDICO && crmValido()) return true;
    return false;
  }

  bool step1Valido() =>
      nomeValido() && telefoneValido() && dataNascimentoValida();
  bool step2Valido() =>
      emailValido() && senhaValida() && senhaRepeticaoValida();
  bool step3PacienteValido() => alturaValida() && pesoValido();
  bool step3MedicoValido() => espealizacoesValida() && descricaoValido();
  bool step4Valido() {
    if (!step1Valido() || !step2Valido()) return false;
    if (tipo == TipoUsuario.PACIENTE && !step3PacienteValido()) return false;
    if (tipo == TipoUsuario.MEDICO && !step3MedicoValido()) return false;
    return true;
  }

  bool isValidStep(int step) {
    bool retorno = false;
    int index = (step == 3 && tipo == TipoUsuario.MEDICO) ? 5 : step;
    switch (index) {
      case 0:
        retorno = step0Valido();
        break;
      case 1:
        retorno = step1Valido();
        break;
      case 2:
        retorno = step2Valido();
        break;
      case 3:
        retorno = step3PacienteValido();
        break;
      case 4:
        retorno = step4Valido();
        break;
      default:
        retorno = step3MedicoValido();
    }
    return retorno;
  }

  StepState getStepState(int step) {
    if (step == activeStepIndex) return StepState.editing;
    if (step != activeStepIndex && isValidStep(step)) return StepState.complete;
    if (step != activeStepIndex && !isValidStep(step)) return StepState.indexed;
    return StepState.indexed;
  }

//===============Focus===================
  FocusNode nomeFocus = FocusNode();
  FocusNode telefoneFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode senhaFocus = FocusNode();
  FocusNode senhaConfirmacaoFocus = FocusNode();
  FocusNode alturaFocus = FocusNode();
  FocusNode pesoFocus = FocusNode();
  FocusNode descricaoFocus = FocusNode();
  FocusNode saudeComorbidadesFocus = FocusNode();
  FocusNode saudeAlergiasFocus = FocusNode();
  FocusNode saudePreDisposicoesFocus = FocusNode();

  requestFirstFieldFocus(BuildContext context) {
    int step = activeStepIndex;
    if (tipo == TipoUsuario.MEDICO && step == 2) step = 3;
    switch (step) {
      case 0:
        nomeFocus.requestFocus();
        break;
      case 1:
        emailFocus.requestFocus();
        break;
      case 2:
        alturaFocus.requestFocus();
        break;
      case 3:
        descricaoFocus.requestFocus();
        break;
    }
  }

  Future<DateTime?> getCalendario(BuildContext context) async {
    FocusScope.of(context).unfocus();
    dataNascimento = await showDatePicker(
      context: context,
      locale: const Locale("pt"),
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 36500)),
      lastDate: DateTime.now(),
    );
  }

  //==========STEP 0=======================
  //=====Variaveis=====
  final _tipo = TipoUsuario.PACIENTE.obs;
  final _cpf = Rx<String?>(null);
  final _crm = Rx<String?>(null);
  final _isCrmValid = false.obs;
  final _crmUf = 'SC'.obs;
  //=====Getters e Setters=====
  get tipo => this._tipo.value;
  setTipo(value) {
    if (value == TipoUsuario.PACIENTE) {
      clearTextControllers();
    }
    this._tipo.value = value;
  }

  get tipoName => _tipo.value.name;

  get cpf => this._cpf.value;
  setCpf(value) => this._cpf.value = value;
  get crmUf => this._crmUf.value;
  setCrmUf(value) => this._crmUf.value = value;
  get isCrmValid => this._isCrmValid.value;
  set isCrmValid(value) => this._isCrmValid.value = value;

  get crm => this._crm.value;
  setCrm(value) => this._crm.value = value;
  //=====Validações=====

  bool crmValido() =>
      isEditing || crm != null && crm.trim().isNotEmpty && crmVerifica;

  String? get crmErroMensagem {
    if (crm == null || crmValido()) return null;
    if (!isCrmValid) return 'CRM inválido ou inativo';
    if (!crmVerifica) return 'CRM em uso';
    return 'Campo obrigatório ';
  }

  bool cpfValido() =>
      (cpf == cpfTemp && isEditing) ||
      cpf != null &&
          cpf.trim().isNotEmpty &&
          cpf.trim().length == 14 &&
          cpfVerifica;

  String? get cpfErroMensagem {
    if (cpf == null || cpfValido()) return null;
    if (!cpfVerifica && cpf.length == 14) return 'CPF em uso';
    return 'Campo obrigatório ';
  }

//==========STEP 1=======================
  //=====Variaveis=====
  final _foto = Rx<dynamic?>(null);
  final _dataNascimento = Rx<DateTime?>(null);
  final _nome = Rx<String?>(null);
  final nomeController = TextEditingController();
  final _telefone = Rx<String?>(null);
  final telefoneController = TextEditingController();
  File? _tmpFile;

  //=====Getters e Setters=====

  get foto => this._foto.value;
  set foto(value) => this._foto.value = value;
  get dataNascimento => this._dataNascimento.value;
  set dataNascimento(value) => this._dataNascimento.value = value;
  String get formataDataNascimento => dataNascimento == null
      ? ''
      : DateFormat('dd/MM/yyyy').format(dataNascimento);
  get nome => this._nome.value;
  setNome(value) => this._nome.value = value;
  get telefone => this._telefone.value;
  setTelefone(value) => this._telefone.value = value;

  //=====Validações=====
  bool nomeValido() =>
      nome != null &&
      nome.trim().isNotEmpty &&
      nome.trim().length >= 3 &&
      nome.trim().length <= 100;
  String? get nomeErroMensagem {
    if (nome == null || nomeValido()) return null;
    if (nome.trim().length < 3) return 'mínimo de 3 caracteres';
    return 'Campo obrigatório ';
  }

  bool telefoneValido() =>
      telefone != null &&
      telefone.trim().isNotEmpty &&
      telefone.trim().length <= 50;
  String? get telefoneErroMensagem {
    if (telefone == null || telefoneValido()) return null;
    return 'Campo obrigatório ';
  }

  bool fotoValida() => foto != null;

  bool dataNascimentoValida() => dataNascimento != null;

  void onImageSelected(File image) async {
    Get.back();
    _tmpFile = File(image.path);
    if (_tmpFile != null) {
      foto = _tmpFile;
    }
  }

//==========STEP 2=======================
  //=====Variaveis=====
  final _email = Rx<String?>(null);
  final _senha = Rx<String?>(null);
  final _emailVerifica = false.obs;
  final _crmVerifica = false.obs;
  final _cpfVerifica = false.obs;
  final _senhaRepeticao = Rx<String?>(null);

  final _genero = Genero.MASCULINO.obs;
  //=====Getters e Setters=====
  get email => this._email.value;
  setEmail(value) => this._email.value = value;
  get emailVerifica => this._emailVerifica.value;
  set emailVerifica(value) => this._emailVerifica.value = value;
  get crmVerifica => this._crmVerifica.value;
  set crmVerifica(value) => this._crmVerifica.value = value;
  get cpfVerifica => this._cpfVerifica.value;
  set cpfVerifica(value) => this._cpfVerifica.value = value;
  get senha => this._senha.value;
  setSenha(value) => this._senha.value = value;
  get senhaRepeticao => this._senhaRepeticao.value;
  setSenhaRepeticao(value) => this._senhaRepeticao.value = value;

  get genero => this._genero.value;
  setGenero(value) => this._genero.value = value;
  get generoName => _genero.value.name;

  //=====Validações=====
  bool emailValido() =>
      isEditing ||
      email != null &&
          email.trim().isNotEmpty &&
          email.toString().isEmailValid() &&
          email.trim().length <= 50 &&
          emailVerifica;

  String? get emailErroMensagem {
    if (email == null || emailValido()) return null;
    if (email != null && !email.toString().isEmailValid()) {
      return 'E-mail inválido';
    }
    if (!emailVerifica) return 'E-mail em uso';
    return 'Campo obrigatório ';
  }

  bool senhaValida() =>
      (senha == null && isEditing) ||
      senha != null &&
          senha.trim().isNotEmpty &&
          senha.trim().length >= 8 &&
          senha.trim().length <= 50;

  String? get senhaErroMensagem {
    if (senha == null || senhaValida()) return null;
    if (senha.trim().length < 8) return 'mínimo de 8 caracteres';
    return 'Campo obrigatório ';
  }

  bool senhaRepeticaoValida() =>
      (senha == null && isEditing) ||
      senhaRepeticao != null && senha.trim() == senhaRepeticao.trim();

  String? get senhaRepeticaoErroMensagem {
    if (senha != null &&
        senhaRepeticao != null &&
        senha != senhaRepeticao.trim()) return 'As senhas são diferentes';
    return null;
  }

//==========STEP 3 Paciente=======================
//=====Variaveis=====

  final _altura = Rx<String?>(null);
  final _peso = Rx<String?>(null);
  final _comorbidades = ''.obs;
  final _alergiasMedicamentosas = ''.obs;
  final _predisposicaoGenetica = ''.obs;
  //=====Getters e Setters=====
  get altura => this._altura.value;
  setAltura(value) => this._altura.value = '$value'.replaceAll(',', '.');
  get peso => this._peso.value;
  setPeso(value) => this._peso.value = '$value'.replaceAll(',', '.');
  get comorbidades => this._comorbidades.value;
  setComorbidades(value) => this._comorbidades.value = value;
  get alergiasMedicamentosas => this._alergiasMedicamentosas.value;
  setAlergiasMedicamentosas(value) =>
      this._alergiasMedicamentosas.value = value;
  get predisposicaoGenetica => this._predisposicaoGenetica.value;
  setPredisposicaoGenetica(value) => this._predisposicaoGenetica.value = value;
  //=====Validações=====

  bool alturaValida() => altura != null && altura.trim().isNotEmpty;

  String? get alturaErroMensagem {
    if (altura == null || alturaValida()) return null;
    return 'Campo obrigatório ';
  }

  bool pesoValido() => peso != null && peso.trim().isNotEmpty;

  String? get pesoErroMensagem {
    if (peso == null || pesoValido()) return null;
    return 'Campo obrigatório ';
  }

//==========STEP 3 Médico=======================
//=====Variaveis=====
  final _descricao = Rx<String?>(null);
  final especializacoes = <Especializacao>[].obs;
  final especializacoesSelecionadas = <Especializacao>[].obs;
  final _isEspecializacaoUntouched = true.obs;
  //=====Getters e Setters=====
  get descricao => this._descricao.value;
  setDescricao(value) => this._descricao.value = value;
  get isEspecializacaoUntouched => this._isEspecializacaoUntouched.value;
  setIsEspecializacaoUntouched(value) =>
      this._isEspecializacaoUntouched.value = value;
  setEspecializacoes(value) {
    setIsEspecializacaoUntouched(false);
    List<Especializacao> values = [];
    value.forEach((element) => values.add(element!));
    especializacoesSelecionadas.assignAll(values);
  }

  final descricaoController = TextEditingController();
  //=====Validações=====

  bool descricaoValido() =>
      descricao != null &&
      descricao.trim().isNotEmpty &&
      descricao.trim().length <= 250;

  String? get descricaoErroMensagem {
    if (descricao == null || descricaoValido()) return null;
    return 'Campo obrigatório ';
  }

  bool espealizacoesValida() => especializacoesSelecionadas.length > 0;

  String? get espealizacoesErroMensagem {
    if (isEspecializacaoUntouched || espealizacoesValida()) return null;
    return 'Selecione suas especializações';
  }
//==========STEP 4=======================

  salvarUsuario() async {
    EasyLoading.showInfo('Salvando...', duration: const Duration(days: 1));
    if (_tmpFile != null) {
      final fileName = basename(_tmpFile!.path);
      final pasta = 'files/$fileName';

      try {
        final ref =
            firebase_storage.FirebaseStorage.instance.ref(pasta).child('file/');
        await ref.putFile(_tmpFile!);
        foto = await ref.getDownloadURL();
      } catch (e) {
        foto = null;
        print('Erro FirebaseStorage imagem');
      }
    }
    var func;
    if (tipo == TipoUsuario.PACIENTE) {
      Paciente paciente = Paciente(
          altura: double.parse(altura ?? '0.0'),
          peso: double.parse(peso ?? '0.0'),
          cpf: cpf,
          comorbidades: comorbidades.isNotEmpty ? comorbidades : 'Nenhuma',
          alergiasMedicamentosas: alergiasMedicamentosas.isNotEmpty
              ? alergiasMedicamentosas
              : 'Nenhuma',
          preDisposicaoGenetica: predisposicaoGenetica.isNotEmpty
              ? predisposicaoGenetica
              : 'Nenhuma',
          tipo: tipo,
          nome: nome,
          email: email,
          senha: senha ?? '',
          dataNascimento: dataNascimento,
          telefone: telefone,
          fotoPath: foto,
          ativo: 1,
          fcmToken: '',
          genero: genero);

      if (_id.value != null) paciente.id = _id.value;

      func = repository.salvarUsuario<Paciente>(paciente);
    }

    if (tipo == TipoUsuario.MEDICO) {
      Medico medico = Medico(
        descricao: descricao,
        crms: List<Crm>.empty(),
        tipo: tipo,
        nome: nome,
        email: email,
        senha: senha ?? '',
        fcmToken: '',
        dataNascimento: dataNascimento,
        telefone: telefone,
        fotoPath: foto,
        ativo: 1,
        genero: genero,
      );
      Crm crmObj = Crm(
          crm: crm, estado_sigla: crmUf, especializacoes: <Especializacao>[]);

      especializacoesSelecionadas.forEach((especializacao) {
        crmObj.especializacoes!.add(especializacao);
      });
      if (isEditing) {
        crmObj.id = usuario.crms[0].id;
      }
      medico.crms = <Crm>[];
      medico.crms.add(crmObj);
      if (_id.value != null) medico.id = _id.value;
      func = repository.salvarUsuario<Medico>(medico);
    }

    func.then((retorno) {
      EasyLoading.dismiss();
      if (!retorno) {
        EasyLoading.instance.backgroundColor = Colors.red;
        EasyLoading.showError('Erro ao salvar');
        EasyLoadingConfig();
      } else {
        EasyLoading.showSuccess('Salvo com sucesso');
        Future.delayed(const Duration(seconds: 1)).then((value) {
          EasyLoadingConfig();
          if (isEditing) {
            loginController
                .getUsuario()
                .then((val) => Get.offNamed(Routes.CONTA));
          } else {
            loginController.setEmail(email);
            loginController.setSenha(senha);
            loginController.verificaLogin();
          }
        });
      }
    });
  }

  clearTextControllers() {
    setNome(null);
    nomeController.clear();
    setTelefone(null);
    telefoneController.clear();
    setDescricao(null);
    descricaoController.clear();
  }

  validaCRM() {
    return;
    if (crm == null) return;
    repository.validaCRM(crm, crmUf).then((retorno) {
      if (retorno is bool) {
        isCrmValid = false;
        clearTextControllers();
      } else {
        isCrmValid = retorno['SITUACAO'] == 'Ativo';
        setNome(retorno['NOME']);
        nomeController.text = nome;
        setTelefone(retorno['TELEFONE']);
        telefoneController.text = telefone;
        setDescricao(retorno['ENDERECO']);
        descricaoController.text = descricao;
      }
    });
  }

  verificaEmail() {
    repository
        .verificaDadosRepetidos(email: email, tipoPesquisa: 'email')
        .then((retorno) => emailVerifica = retorno);
  }

  verificaCrm() {
    repository
        .verificaDadosRepetidos(crm: crm, uf: crmUf, tipoPesquisa: 'crm')
        .then((retorno) => crmVerifica = retorno);
  }

  verificaCpf() {
    repository
        .verificaDadosRepetidos(cpf: cpf, tipoPesquisa: 'cpf')
        .then((retorno) => cpfVerifica = retorno);
  }

  getEspecializacoes() {
    repository.getEspecializacoes().then((List<Especializacao>? retorno) {
      this.especializacoes.clear();
      this.especializacoes.assignAll(retorno!);
    });
  }
}
