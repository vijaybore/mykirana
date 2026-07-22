/// Shared validators for optional contact fields. Both return null
/// (valid) for an empty string — these fields are optional, so "not
/// filled in" is not a validation error, only "filled in wrong" is.
class Validators {
  Validators._();

  static final _phoneRegExp = RegExp(r'^[0-9]{10}$');
  static final _upiRegExp = RegExp(r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$');

  /// Expects a plain 10-digit Indian mobile number, no country code,
  /// spaces, or dashes — matches what the OTP login flow expects too.
  static String? phone(String? value, {required String errorMessage}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return _phoneRegExp.hasMatch(trimmed) ? null : errorMessage;
  }

  /// UPI IDs look like "name@bank" — this is a shape check, not proof
  /// the ID actually exists or belongs to this shop.
  static String? upiId(String? value, {required String errorMessage}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return _upiRegExp.hasMatch(trimmed) ? null : errorMessage;
  }
}
