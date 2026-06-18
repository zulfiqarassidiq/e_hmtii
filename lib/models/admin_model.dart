class AdminModel {
  final String idAdmin;
  final String password;

  AdminModel({required this.idAdmin, required this.password});

  factory AdminModel.fromMap(Map<String, dynamic> map) => AdminModel(
        idAdmin: map['id_admin'] as String,
        password: map['password'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id_admin': idAdmin,
        'password': password,
      };
}
