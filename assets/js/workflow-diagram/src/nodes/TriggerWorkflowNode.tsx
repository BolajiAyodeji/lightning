import React, { memo } from 'react';

import { Handle, Position } from 'react-flow-renderer';
import type { NodeProps } from 'react-flow-renderer';
import type { Trigger, Workflow } from '../types';
import cronstrue from 'cronstrue';

function descriptionFor({ trigger }: { trigger: Trigger }): string | null {
  switch (trigger.type) {
    case 'webhook':
      return `When data is received at ${trigger.webhookUrl}`;
    case 'cron':
      try {
        return cronstrue.toString(trigger.cronExpression);
      } catch (_error) {
        return null;
      }
    default:
      return null;
  }
}

const TriggerWorkflowNode = ({
  data,
  isConnectable,
  sourcePosition = Position.Bottom,
}: NodeProps & {
  data: { label: string; trigger: Trigger; workflow: Workflow };
}): JSX.Element => {
  const workflowName = data.workflow.name ?? 'Untitled';
  const description = descriptionFor(data);
  return (
    <div
      className="bg-white cursor-pointer h-full py-1 px-1 rounded-md shadow-sm
        text-center text-xs ring-0.5 ring-black ring-opacity-5"
    >
      <div className="flex flex-col items-center justify-center h-full text-center">
        <p>{workflowName}</p>
        <p
          title={description || ''}
          className="text-[0.6rem] italic text-ellipsis overflow-hidden whitespace-pre-line"
        >
          {description}
        </p>
      </div>
      <Handle
        type="source"
        position={sourcePosition}
        isConnectable={isConnectable}
        style={{ border: 'none', height: 0, top: 0 }}
      />
    </div>
  );
};

TriggerWorkflowNode.displayName = 'TriggerWorkflowNode';

export default memo(TriggerWorkflowNode);
