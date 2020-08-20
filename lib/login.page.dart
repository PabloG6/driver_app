import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/main.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _verificationCodeController = TextEditingController();

  Firestore firestore = Firestore.instance;
  CollectionReference couriersCollection;

  @override
  Widget build(BuildContext context) {
    couriersCollection = firestore.collection("couriers");
    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Courier Name",
                      labelStyle: Theme.of(context).textTheme.bodyText1,
                    ),
                    controller: _nameController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Email Address",
                        labelStyle: Theme.of(context).textTheme.bodyText1),
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Verification Code",
                        labelStyle: Theme.of(context).textTheme.bodyText1),
                    keyboardType: TextInputType.numberWithOptions(),
                    controller: _verificationCodeController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ButtonTheme(
                    padding: EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    minWidth: double.infinity,
                    child: FlatButton(
                      color: Colors.indigo,
                      onPressed: () async {
                        final courierDocuments = await couriersCollection
                            .where("couriername", isEqualTo: _nameController.text)
                            .getDocuments();
                        //get the first courier with this name.
                        print("name ==============> ${_nameController.text}");
                        final courierDocument =
                            courierDocuments.documents.first;
                        final driversCollection = couriersCollection
                            .document(courierDocument.documentID)
                            .collection("drivers");
                        final driverQuery = await driversCollection
                            .where("verification_code",
                                isEqualTo: int.parse(_verificationCodeController.text))
                            .where("email", isEqualTo: _emailController.text)
                            .getDocuments();
                        if (driverQuery.documents.length > 0) {
                          final driver = driverQuery.documents.first;
                          await driversCollection.document(driver.documentID).updateData({"isOnline": true});
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                            return MyHomePage(driver: driver, courier: courierDocument,);
                          }));
                        }
                      },
                      child: Text("Sign In",
                          style: Theme.of(context).textTheme.button.copyWith(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
