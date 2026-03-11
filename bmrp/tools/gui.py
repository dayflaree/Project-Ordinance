#!/usr/bin/env python3
from __future__ import annotations

import shlex
import sys
from pathlib import Path

try:
    from PySide6.QtCore import QProcess, Qt
    from PySide6.QtGui import QAction, QTextCursor
    from PySide6.QtWidgets import (
        QApplication,
        QCheckBox,
        QComboBox,
        QDoubleSpinBox,
        QFileDialog,
        QFormLayout,
        QHBoxLayout,
        QLabel,
        QLineEdit,
        QMainWindow,
        QMessageBox,
        QPlainTextEdit,
        QPushButton,
        QSpinBox,
        QTabWidget,
        QVBoxLayout,
        QWidget,
    )
except ImportError as exc:
    raise SystemExit("PySide6 is required to run tools/gui.py") from exc


PROJECT_ROOT = Path(__file__).resolve().parent.parent
TOOLS_DIR = PROJECT_ROOT / "tools"


class PathField(QWidget):
    def __init__(
        self,
        *,
        parent: QWidget | None = None,
        directory: bool = False,
        save: bool = False,
        caption: str,
        name_filter: str = "All Files (*)",
    ) -> None:
        super().__init__(parent)
        self.directory = directory
        self.save = save
        self.caption = caption
        self.name_filter = name_filter

        self.line_edit = QLineEdit(self)
        self.browse_button = QPushButton("Browse...", self)
        self.browse_button.clicked.connect(self.browse)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(self.line_edit, 1)
        layout.addWidget(self.browse_button)

    def text(self) -> str:
        return self.line_edit.text().strip()

    def set_text(self, value: str) -> None:
        self.line_edit.setText(value)

    def browse(self) -> None:
        start_dir = self.text() or str(PROJECT_ROOT)
        if self.directory:
            selected = QFileDialog.getExistingDirectory(self, self.caption, start_dir)
            if selected:
                self.set_text(selected)
            return

        if self.save:
            selected, _ = QFileDialog.getSaveFileName(
                self,
                self.caption,
                start_dir,
                self.name_filter,
            )
        else:
            selected, _ = QFileDialog.getOpenFileName(
                self,
                self.caption,
                start_dir,
                self.name_filter,
            )

        if selected:
            self.set_text(selected)


class ToolTab(QWidget):
    title = ""
    description = ""
    script_name = ""

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.process = QProcess(self)
        self.process.setProgram(sys.executable)
        self.process.setWorkingDirectory(str(PROJECT_ROOT))
        self.process.setProcessChannelMode(QProcess.MergedChannels)
        self.process.readyReadStandardOutput.connect(self.on_ready_read)
        self.process.finished.connect(self.on_finished)
        self.process.errorOccurred.connect(self.on_error)

        self.description_label = QLabel(self.description, self)
        self.description_label.setWordWrap(True)
        self.description_label.setTextInteractionFlags(Qt.TextSelectableByMouse)

        self.form_layout = QFormLayout()
        self.form_layout.setFieldGrowthPolicy(QFormLayout.ExpandingFieldsGrow)

        self.run_button = QPushButton("Run", self)
        self.stop_button = QPushButton("Stop", self)
        self.clear_button = QPushButton("Clear Output", self)

        self.output = QPlainTextEdit(self)
        self.output.setReadOnly(True)
        self.output.setLineWrapMode(QPlainTextEdit.NoWrap)

        self.run_button.clicked.connect(self.run_tool)
        self.stop_button.clicked.connect(self.stop_tool)
        self.clear_button.clicked.connect(self.output.clear)
        self.stop_button.setEnabled(False)

        button_row = QHBoxLayout()
        button_row.addWidget(self.run_button)
        button_row.addWidget(self.stop_button)
        button_row.addStretch(1)
        button_row.addWidget(self.clear_button)

        layout = QVBoxLayout(self)
        layout.addWidget(self.description_label)
        layout.addLayout(self.form_layout)
        layout.addLayout(button_row)
        layout.addWidget(self.output, 1)

        self.build_form()

    @property
    def script_path(self) -> Path:
        return TOOLS_DIR / self.script_name

    def build_form(self) -> None:
        raise NotImplementedError

    def build_arguments(self) -> list[str]:
        raise NotImplementedError

    def append_output(self, text: str) -> None:
        if not text:
            return

        cursor = self.output.textCursor()
        cursor.movePosition(QTextCursor.End)
        cursor.insertText(text)
        self.output.setTextCursor(cursor)
        self.output.ensureCursorVisible()

    def set_running(self, running: bool) -> None:
        self.run_button.setEnabled(not running)
        self.stop_button.setEnabled(running)

    def run_tool(self) -> None:
        if self.process.state() != QProcess.NotRunning:
            return

        if not self.script_path.is_file():
            QMessageBox.critical(self, self.title, f"Script not found:\n{self.script_path}")
            return

        try:
            arguments = [str(self.script_path), *self.build_arguments()]
        except ValueError as exc:
            QMessageBox.warning(self, self.title, str(exc))
            return

        command_preview = " ".join(shlex.quote(part) for part in [sys.executable, *arguments])
        self.append_output(f"\n> {command_preview}\n\n")
        self.process.start(sys.executable, arguments)
        if not self.process.waitForStarted(3000):
            QMessageBox.critical(
                self,
                self.title,
                f"Failed to start {self.script_name}.\n{self.process.errorString()}",
            )
            return

        self.set_running(True)

    def stop_tool(self) -> None:
        if self.process.state() == QProcess.NotRunning:
            return

        self.append_output("\n[stopping process]\n")
        self.process.kill()

    def on_ready_read(self) -> None:
        data = bytes(self.process.readAllStandardOutput()).decode("utf-8", errors="replace")
        self.append_output(data)

    def on_finished(self, exit_code: int, exit_status: QProcess.ExitStatus) -> None:
        status = "normal" if exit_status == QProcess.NormalExit else "crashed"
        self.append_output(f"\n[process finished: exit_code={exit_code}, status={status}]\n")
        self.set_running(False)

    def on_error(self, error: QProcess.ProcessError) -> None:
        if error == QProcess.UnknownError:
            return
        self.append_output(f"\n[process error: {self.process.errorString()}]\n")
        self.set_running(False)


class GenerateScapesTab(ToolTab):
    title = "Generate Scapes"
    description = (
        "Convert a Source 1 soundscape KeyValues file into generated Lua scape registrations."
    )
    script_name = "generate_scapes_from_soundscapes.py"

    def build_form(self) -> None:
        self.input_path = PathField(
            parent=self,
            caption="Select input soundscapes file",
            name_filter="Text Files (*.txt);;All Files (*)",
        )
        self.output_path = PathField(
            parent=self,
            caption="Select output Lua file",
            save=True,
            name_filter="Lua Files (*.lua);;All Files (*)",
        )
        self.mix_tag = QLineEdit("facility", self)

        self.no_mix_tag = QCheckBox("Disable mix tag output", self)

        self.priority = QSpinBox(self)
        self.priority.setRange(-9999, 9999)
        self.priority.setValue(30)

        self.fade_in = QDoubleSpinBox(self)
        self.fade_in.setRange(0.0, 9999.0)
        self.fade_in.setDecimals(3)
        self.fade_in.setSingleStep(0.1)
        self.fade_in.setValue(1.0)

        self.fade_out = QDoubleSpinBox(self)
        self.fade_out.setRange(0.0, 9999.0)
        self.fade_out.setDecimals(3)
        self.fade_out.setSingleStep(0.1)
        self.fade_out.setValue(1.0)

        self.pause_legacy = QCheckBox("Pause legacy ambient", self)
        self.pause_legacy.setChecked(True)

        self.random_radius = QLineEdit("256,768", self)

        self.dedupe = QComboBox(self)
        self.dedupe.addItems(["last", "first", "none"])

        self.skip_empty = QCheckBox("Skip empty top-level scapes", self)

        self.input_path.line_edit.textChanged.connect(self.sync_output_suggestion)

        self.form_layout.addRow("Input file", self.input_path)
        self.form_layout.addRow("Output file", self.output_path)
        self.form_layout.addRow("Mix tag", self.mix_tag)
        self.form_layout.addRow("", self.no_mix_tag)
        self.form_layout.addRow("Priority", self.priority)
        self.form_layout.addRow("Fade in", self.fade_in)
        self.form_layout.addRow("Fade out", self.fade_out)
        self.form_layout.addRow("", self.pause_legacy)
        self.form_layout.addRow("Random radius", self.random_radius)
        self.form_layout.addRow("Duplicate IDs", self.dedupe)
        self.form_layout.addRow("", self.skip_empty)

    def sync_output_suggestion(self) -> None:
        if self.output_path.text():
            return

        input_text = self.input_path.text()
        if not input_text:
            return

        input_path = Path(input_text)
        name = input_path.stem or "generated_scapes"
        if name.startswith("soundscapes_"):
            name = name[len("soundscapes_") :]

        suggested = PROJECT_ROOT / "gamemode" / "schema" / "config" / "maps" / f"{name}_generated.lua"
        self.output_path.set_text(str(suggested))

    def build_arguments(self) -> list[str]:
        input_path = self.input_path.text()
        output_path = self.output_path.text()

        if not input_path:
            raise ValueError("Input file is required.")
        if not output_path:
            raise ValueError("Output file is required.")

        arguments = [
            "--input",
            input_path,
            "--output",
            output_path,
            "--priority",
            str(self.priority.value()),
            "--fade-in",
            str(self.fade_in.value()),
            "--fade-out",
            str(self.fade_out.value()),
            "--random-relative-radius",
            self.random_radius.text().strip() or "256,768",
            "--dedupe",
            self.dedupe.currentText(),
        ]

        if self.no_mix_tag.isChecked():
            arguments.append("--no-mix-tag")
        else:
            arguments.extend(["--mix-tag", self.mix_tag.text().strip()])

        if not self.pause_legacy.isChecked():
            arguments.append("--no-pause-legacy-ambient")

        if self.skip_empty.isChecked():
            arguments.append("--skip-empty")

        return arguments


class AdjustLabcreteTab(ToolTab):
    title = "Adjust Labcrete VMF"
    description = "Adjust matching LABCRETE texture axes in a VMF file and optionally write a backup."
    script_name = "adjust_labcrete_vmf.py"

    def build_form(self) -> None:
        self.vmf_path = PathField(
            parent=self,
            caption="Select VMF file",
            name_filter="VMF Files (*.vmf);;All Files (*)",
        )
        self.dry_run = QCheckBox("Dry run", self)
        self.no_backup = QCheckBox("Do not create .bak backup", self)

        self.form_layout.addRow("VMF file", self.vmf_path)
        self.form_layout.addRow("", self.dry_run)
        self.form_layout.addRow("", self.no_backup)

    def build_arguments(self) -> list[str]:
        vmf_path = self.vmf_path.text()
        if not vmf_path:
            raise ValueError("VMF file is required.")

        arguments = [vmf_path]
        if self.dry_run.isChecked():
            arguments.append("--dry-run")
        if self.no_backup.isChecked():
            arguments.append("--no-backup")
        return arguments


class StripVmtTab(ToolTab):
    title = "Strip VMT Keys"
    description = (
        "Recursively remove bumpmap, envmap, and phong-related keys from .vmt files in a directory."
    )
    script_name = "strip_vmt_bump_env_phong.py"

    def build_form(self) -> None:
        self.input_dir = PathField(
            parent=self,
            directory=True,
            caption="Select materials root directory",
        )
        self.backup_ext = QLineEdit(self)
        self.backup_ext.setPlaceholderText(".bak")
        self.dry_run = QCheckBox("Dry run", self)
        self.quiet = QCheckBox("Quiet output", self)

        self.form_layout.addRow("Input directory", self.input_dir)
        self.form_layout.addRow("Backup extension", self.backup_ext)
        self.form_layout.addRow("", self.dry_run)
        self.form_layout.addRow("", self.quiet)

    def build_arguments(self) -> list[str]:
        input_dir = self.input_dir.text()
        if not input_dir:
            raise ValueError("Input directory is required.")

        arguments = [input_dir]
        backup_ext = self.backup_ext.text().strip()
        if backup_ext:
            arguments.extend(["--backup-ext", backup_ext])
        if self.dry_run.isChecked():
            arguments.append("--dry-run")
        if self.quiet.isChecked():
            arguments.append("--quiet")
        return arguments


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("BMRP Tools")
        self.resize(1080, 760)

        tabs = QTabWidget(self)
        tabs.addTab(GenerateScapesTab(self), "Generate Scapes")
        tabs.addTab(AdjustLabcreteTab(self), "Adjust Labcrete")
        tabs.addTab(StripVmtTab(self), "Strip VMT Keys")

        self.setCentralWidget(tabs)

        quit_action = QAction("Quit", self)
        quit_action.triggered.connect(self.close)
        file_menu = self.menuBar().addMenu("File")
        file_menu.addAction(quit_action)

        status = self.statusBar()
        status.showMessage(f"Python: {sys.executable} | Project root: {PROJECT_ROOT}")


def main() -> int:
    app = QApplication(sys.argv)
    app.setApplicationName("BMRP Tools")
    app.setOrganizationName("BMRP")

    window = MainWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
