import {
  MigrationInterface,
  QueryRunner,
  TableColumn,
  TableForeignKey,
} from "typeorm";

export class ClaimColumnsSafeMigration20260405000100 implements MigrationInterface {
  name = "ClaimColumnsSafeMigration20260405000100";

  public async up(queryRunner: QueryRunner): Promise<void> {
    const claimTable = await queryRunner.getTable("claim");
    if (!claimTable) return;

    const hasMachineId = claimTable.findColumnByName("machineId");
    const hasLegacyMachineMachineId =
      claimTable.findColumnByName("machineMachineId");

    // Handle the relation ID rename safely so existing data is preserved.
    if (!hasMachineId && hasLegacyMachineMachineId) {
      await queryRunner.renameColumn("claim", "machineMachineId", "machineId");
    }

    if (
      !claimTable.findColumnByName("machineId") &&
      !hasLegacyMachineMachineId
    ) {
      await queryRunner.addColumn(
        "claim",
        new TableColumn({
          name: "machineId",
          type: "integer",
          isNullable: false,
        }),
      );
    }

    const refreshedClaimTable = await queryRunner.getTable("claim");
    if (!refreshedClaimTable) return;

    if (!refreshedClaimTable.findColumnByName("completedAt")) {
      await queryRunner.addColumn(
        "claim",
        new TableColumn({
          name: "completedAt",
          type: "timestamp",
          isNullable: true,
        }),
      );
    }

    if (!refreshedClaimTable.findColumnByName("unclaimedAt")) {
      await queryRunner.addColumn(
        "claim",
        new TableColumn({
          name: "unclaimedAt",
          type: "timestamp",
          isNullable: true,
        }),
      );
    }

    const nullMachineIdCountResult: Array<{ count: string }> =
      await queryRunner.query(
        'SELECT COUNT(*)::text AS count FROM "claim" WHERE "machineId" IS NULL',
      );
    const nullMachineIdCount = parseInt(
      nullMachineIdCountResult[0]?.count ?? "0",
      10,
    );
    if (nullMachineIdCount > 0) {
      throw new Error(
        `Cannot enforce NOT NULL on claim.machineId: found ${nullMachineIdCount} rows with NULL machineId`,
      );
    }

    await queryRunner.changeColumn(
      "claim",
      "machineId",
      new TableColumn({
        name: "machineId",
        type: "integer",
        isNullable: false,
      }),
    );

    const claimMachineIdColumn =
      refreshedClaimTable.findColumnByName("machineId");
    const hasClaimMachineFk = refreshedClaimTable.foreignKeys.some(
      (fk) => fk.columnNames.length === 1 && fk.columnNames[0] === "machineId",
    );

    if (claimMachineIdColumn && !hasClaimMachineFk) {
      await queryRunner.createForeignKey(
        "claim",
        new TableForeignKey({
          columnNames: ["machineId"],
          referencedTableName: "machine",
          referencedColumnNames: ["machineId"],
          onDelete: "NO ACTION",
          onUpdate: "NO ACTION",
        }),
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const claimTable = await queryRunner.getTable("claim");
    if (!claimTable) return;

    const claimMachineFk = claimTable.foreignKeys.find(
      (fk) => fk.columnNames.length === 1 && fk.columnNames[0] === "machineId",
    );
    if (claimMachineFk) {
      await queryRunner.dropForeignKey("claim", claimMachineFk);
    }

    if (claimTable.findColumnByName("unclaimedAt")) {
      await queryRunner.dropColumn("claim", "unclaimedAt");
    }

    if (claimTable.findColumnByName("completedAt")) {
      await queryRunner.dropColumn("claim", "completedAt");
    }

    const refreshedClaimTable = await queryRunner.getTable("claim");
    if (!refreshedClaimTable) return;

    if (refreshedClaimTable.findColumnByName("machineId")) {
      await queryRunner.renameColumn("claim", "machineId", "machineMachineId");
    }
  }
}
