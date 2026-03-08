import os

file_path = r'C:\Users\30444\AppData\Local\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "namespace" not in content:
    content = content.replace('android {', "android {\n    namespace 'dev.isar.isar_flutter_libs'")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Namespace added successfully")
else:
    print("Namespace already exists")