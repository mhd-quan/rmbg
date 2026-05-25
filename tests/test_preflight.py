from unittest import TestCase, main

from rmbg_backend.preflight import CheckResult, PreflightReport


class PreflightTests(TestCase):
    def test_report_serializes_checks(self) -> None:
        report = PreflightReport(
            ok=True,
            checks=[CheckResult(name="python", status="ok", message="ok")],
            python="3.12",
            platform="macOS",
            machine="x86_64",
            executable="/usr/bin/python",
            model_id="briaai/RMBG-2.0",
            auto_device="cpu",
        )

        self.assertEqual(report.to_dict()["checks"][0]["name"], "python")
        self.assertTrue(report.to_dict()["ok"])


if __name__ == "__main__":
    main()
