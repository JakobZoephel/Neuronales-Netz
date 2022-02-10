# Installation
Das Programm kann mit der Datei "installer.bat" installiert werden. Diese ist eine Batch-Datei, die einige Commands ausführt (dazu öffnet sich ein Terminal, die "cmd"). Man kann die Datei in Firefox als einzelne herunterladen, indem man diese auswählt und anschließend rechts auf "raw" klickt. Wenn man dann Strg und "s" gleichzeitig drückt oder bei einem Rechtsklick "Seite speicherun unter..." auswählt, kann die Datei gespeichert werden.
Beim dem Ausühren der installer.bat Datei oder später des Programmes, erscheint eine Sicherheitswarnung von Windows. Grund dafür ist, dass keine der beiden Datein zertifiziert ist. Das Auführen ist aber trotzdem möglich (und sicher), wenn man auf "weitere Informationen" klickt und anschließend auf "Trotzdem Ausführen".
Zum weiteren Editieren und Ausführen des Programmcodes kann außerdem die IDE Processing benutzt werden: https://processing.org
# Das Neuronale Netz
Das Programm ist ein mit Java in Processing programmiertes Neuronales Netz. Mit ihm können eigene Netze trainiert und angewendet werden, wobei sich der Aufgabenbereich auf das Erkennen von handgeschriebenen Zahlen bezieht. 
Die Grafische Oberfläche ist dabei weitgehend intuitiv gestaltet, es gibt am Anfang drei Möglichkeiten: Das Trainieren eines eigenen Neuronalen Netzes, das "Ausprobieren" eines zuvor trainierten (mit anschließender Visualisierung des Netzes) und zuletzt das Erkennen und Übersetzen in "Computerzahlen" eines Bildes mit einer oder mehreren Gleichungen.
# Das Trainieren
Entscheidet man sich für das Trainieren, hat man zuerst die Möglichkeit das Netz zu definieren. Dabei kann man vorerst die Art der Fehlerfunktion und der Aktivierungsfunktion des Output-Layers bestimmen. Danach können die Hidden-Layers definiert werden. Ein Layer wird dabei von einer Box dargestellt. Links von dem Doppelpunkt (:) befindet sich die Anzahl der Neuronen, rechts die Aktivierungsfunktion die diese Schhicht nutzen soll. Drückt man die ENTER-Taste, wird unter dem ausgewählten Hidden-Layer ein weiterer hinzugefügt.
Klickt man danach auf den grünen Pfeil, gelangt man auf eine neue Übersicht. In dieser kann man verschiedene, das Training betreffende, Parameter einstellen. In der Box am unteren Rand des Fensters wird dabei das ausgewählte Feld kurz erläutert. Klickt man nun abermals auf den grünen Pfeil, beginnt das Training des zuvor definierten Neuronalen Netzes.
# Anmerkung
Das Programm ist noch in einem Stadium, in dem es noch einige Dinge gibt die noch programmiert werden müssen. Beispielsweise hat das Netz momentan noch Probleme, Zahlen mit einer Schriftgröße die nicht 38 Pixel oder ähnliches beträgt richtig zu klassifizieren. Möglicherweise klappt also etwas, was vor einiger Zeit nicht funktioniert hat, bei der nächsten Version besser.
