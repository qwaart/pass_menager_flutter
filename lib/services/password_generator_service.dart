import 'dart:math';

class PasswordGeneratorService {
	String generatePassword({
		int length = 12,
		bool includeUppercase = true,
		bool includeLowercase = true,
		bool includeNumbers = true,
		bool includeSymbols = true,
	}) {
		if (length < 8) length = 8;
		if (length > 32) length = 32;

		String chars = '';
		if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
	    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	    if (includeNumbers) chars += '0123456789';
	    if (includeSymbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

	    if (chars.isEmpty) {
	    	throw Exception('At least one type of character must be included');
	    }

	    final random = Random();
	    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
	}

	String generateStrongPassword() {
		return generatePassword(length: 16, includeSymbols: true);
	}
}