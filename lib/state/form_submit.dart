/// Small immutable state for form submit buttons.
class FormSubmit {
  final bool isBusy;
  final String? error;

  const FormSubmit._({this.isBusy = false, this.error});

  const FormSubmit.idle() : this._();

  const FormSubmit.loading() : this._(isBusy: true);

  const FormSubmit.failed(String error) : this._(error: error);

  bool get hasError => error != null;
}