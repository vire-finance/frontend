part of '_theme.dart';

enum ThemeType { normal, dark }

class AppTheme implements VireTheme {
  
  @override
  ThemeData normalTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: BaseColors.blue400,
      scaffoldBackgroundColor: BaseColors.white,
      
      textTheme: TextTheme(
        displayLarge: FontTheme.heading,
        bodyLarge: FontTheme.paragraph,
      ),
    );
  }

  @override
  ThemeData darkTheme() {
    return normalTheme();
  }

  @override
  ThemeData mapTheme(ThemeType type) {
    return normalTheme();
  }
}