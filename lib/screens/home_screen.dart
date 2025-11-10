import 'package:flutter/material.dart';
// import '../services/database_service.dart'; // i`ll add it later

class HomeScreen extends StatefulWidget {
	@override

	_HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
	// its fake list for test, real db i`ll add later 
	final List<String> _passwords = ['Password_1(test)', 'Password_2(test)'];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text('Passwords'),
				backgroundColor: Theme.of(context).colorScheme.inversePrimary,
				actions: [
					IconButton(
						icon: const Icon(Icons.settings),
						onPressed: () {
							// Nothing now, but for future auth
							ScaffoldMessenger.of(context).showSnackBar(
								const SnackBar(content: Text('Setting (soon)')),
							);
						},
					),
				],
			),
			body: _passwords.isEmpty
				? const Center(
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(Icons.lock_outline, size: 64, color: Colors.grey),
							SizedBox(height: 16),
							Text('You have not passwords. Add your first password!', style: TextStyle(fontSize: 18)),
						],
					),
				)
				: ListView.builder(
					itemCount: _passwords.length,
					itemBuilder: (context, index) {
						return Card(
							margin: const EdgeInsets.all(8),
							child: ListTile(
								leading: const Icon(Icons.lock, color: Colors.red),
								title: Text(_passwords[index]),
								subtitle: const Text('Site: example.com | login: user'),
								trailing: IconButton(
									icon: const Icon(Icons.edit),
									onPressed: () {
										ScaffoldMessenger.of(context).showSnackBar(
											SnackBar(content: Text('Edit ${_passwords[index]} (soon)')),
										);
									},
								),
							),
						);
					},
				),
			floatingActionButton: FloatingActionButton(
				onPressed: () {
					setState(() {
						_passwords.add('New password ${DateTime.now().second}');
					});
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(content: Text('Password added! (no :D)')),
					);
				},
				child: const Icon(Icons.add),
			),
		); // Scafold
	}
	//void _addPassword(BuildContext context) {
	//	ToDo: Logic of adding a password(form)
	//}
}